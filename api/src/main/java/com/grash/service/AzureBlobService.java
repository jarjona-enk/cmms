package com.grash.service;

import com.azure.core.util.BinaryData;
import com.azure.core.util.Context;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobHttpHeaders;
import com.azure.storage.blob.models.BlobStorageException;
import com.azure.storage.blob.models.UserDelegationKey;
import com.azure.storage.blob.options.BlobParallelUploadOptions;
import com.azure.storage.blob.sas.BlobSasPermission;
import com.azure.storage.blob.sas.BlobServiceSasSignatureValues;
import com.azure.storage.common.StorageSharedKeyCredential;
import com.grash.exception.CustomException;
import com.grash.model.File;
import com.grash.utils.Helper;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.URLConnection;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

/**
 * Azure Blob Storage backend, selected with {@code STORAGE_TYPE=azure}.
 * <p>
 * Files are returned to the browser as time-limited SAS URLs rather than being
 * proxied through the API (see {@code FileMapper}), so the storage account must
 * be reachable from end-user browsers, not only from the application. It does
 * not have to be internet-facing: a private endpoint works as long as clients
 * can resolve and reach it under the same hostname this service signs with.
 * <p>
 * Two credential modes, chosen by whether an account key is configured:
 * <ul>
 *   <li><b>Account key</b> — a shared-key credential signing service SAS tokens.</li>
 *   <li><b>Managed identity</b> — {@code DefaultAzureCredential} signing user
 *       delegation SAS tokens. Preferred on Azure: nothing secret is stored.
 *       The identity needs <i>Storage Blob Data Contributor</i> (read/write) and
 *       <i>Storage Blob Delegator</i> (to obtain the delegation key).</li>
 * </ul>
 * Like the MinIO and GCP backends, this one stays dormant when unconfigured:
 * the application boots and only file operations fail.
 */
@Service
@RequiredArgsConstructor
public class AzureBlobService implements StorageService {

    /**
     * How long a user delegation key is requested for. It is cached and reused
     * across signatures because obtaining one is a network round trip, and
     * FileMapper signs every file of every listing individually.
     */
    private static final int DELEGATION_KEY_TTL_HOURS = 12;
    /** Renew this long before expiry so a signature never uses a stale key. */
    private static final int DELEGATION_KEY_REFRESH_MARGIN_MINUTES = 30;
    /** Tolerance for clock skew between this host and the storage service. */
    private static final int CLOCK_SKEW_MINUTES = 5;

    @Value("${storage.azure.account-name:}")
    private String accountName;
    @Value("${storage.azure.account-key:}")
    private String accountKey;
    @Value("${storage.azure.container:}")
    private String containerName;
    @Value("${storage.azure.endpoint:}")
    private String endpoint;

    private BlobServiceClient blobServiceClient;
    private BlobContainerClient containerClient;
    private boolean configured = false;
    /** True when signing must go through a user delegation key. */
    private boolean usesManagedIdentity = false;

    private volatile UserDelegationKey delegationKey;
    private volatile OffsetDateTime delegationKeyExpiry;

    @PostConstruct
    private void init() {
        if (accountName.isEmpty() || containerName.isEmpty()) {
            return;
        }
        try {
            String resolvedEndpoint = endpoint.isEmpty()
                    ? "https://" + accountName + ".blob.core.windows.net"
                    : endpoint;

            BlobServiceClientBuilder builder = new BlobServiceClientBuilder().endpoint(resolvedEndpoint);
            if (accountKey.isEmpty()) {
                // No key configured: authenticate as the managed identity (or any
                // other credential DefaultAzureCredential can discover locally).
                usesManagedIdentity = true;
                builder.credential(new DefaultAzureCredentialBuilder().build());
            } else {
                builder.credential(new StorageSharedKeyCredential(accountName, accountKey));
            }

            blobServiceClient = builder.buildClient();
            containerClient = blobServiceClient.getBlobContainerClient(containerName);
            if (!containerClient.exists()) {
                containerClient.create();
            }
            configured = true;
        } catch (BlobStorageException e) {
            throw new CustomException("Error configuring Azure Blob Storage: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    public String upload(MultipartFile file, String folder) {
        checkIfConfigured();
        Helper helper = new Helper();
        String filePath = folder + "/" + helper.generateString() + " " + file.getOriginalFilename();
        try (InputStream inputStream = file.getInputStream()) {
            BlobParallelUploadOptions options = new BlobParallelUploadOptions(inputStream, file.getSize())
                    .setHeaders(new BlobHttpHeaders().setContentType(file.getContentType()));
            containerClient.getBlobClient(filePath).uploadWithResponse(options, null, Context.NONE);
            return filePath;
        } catch (BlobStorageException | IOException e) {
            throw new CustomException(e.getMessage(), HttpStatus.UNPROCESSABLE_ENTITY);
        }
    }

    @Override
    public String upload(byte[] data, String fileName, String folder) {
        checkIfConfigured();
        String filePath = folder + "/" + fileName;
        try {
            // Callers of this overload are generating thumbnails, so JPEG is the
            // right fallback when the name carries no recognisable extension.
            String contentType = URLConnection.guessContentTypeFromName(fileName);
            BlobParallelUploadOptions options =
                    new BlobParallelUploadOptions(BinaryData.fromBytes(data))
                            .setHeaders(new BlobHttpHeaders()
                                    .setContentType(contentType == null ? "image/jpeg" : contentType));
            containerClient.getBlobClient(filePath).uploadWithResponse(options, null, Context.NONE);
            return filePath;
        } catch (BlobStorageException e) {
            throw new CustomException(e.getMessage(), HttpStatus.UNPROCESSABLE_ENTITY);
        }
    }

    @Override
    public byte[] download(String filePath) {
        checkIfConfigured();
        try {
            return containerClient.getBlobClient(filePath).downloadContent().toBytes();
        } catch (BlobStorageException e) {
            if (e.getStatusCode() == HttpStatus.NOT_FOUND.value()) {
                throw new CustomException("File not found", HttpStatus.NOT_FOUND);
            }
            throw new CustomException("Error retrieving file", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    public byte[] download(File file) {
        checkIfConfigured();
        return download(file.getPath());
    }

    @Override
    public String generateSignedUrl(File file, long expirationMinutes) {
        return generateSignedUrl(file.getPath(), expirationMinutes);
    }

    @Override
    public String generateSignedUrl(String filePath, long expirationMinutes) {
        checkIfConfigured();
        // Deliberately no existence check: this is called once per file per
        // listing, and a HEAD per file would multiply every page load by the
        // number of attachments on it. The MinIO backend behaves the same way.
        try {
            BlobClient blobClient = containerClient.getBlobClient(filePath);
            OffsetDateTime expiry = OffsetDateTime.now(ZoneOffset.UTC).plusMinutes(expirationMinutes);
            BlobServiceSasSignatureValues values = new BlobServiceSasSignatureValues(
                    expiry, new BlobSasPermission().setReadPermission(true));

            String sas = usesManagedIdentity
                    ? blobClient.generateUserDelegationSas(values, delegationKey(expiry))
                    : blobClient.generateSas(values);
            return blobClient.getBlobUrl() + "?" + sas;
        } catch (BlobStorageException e) {
            throw new CustomException("Error generating signed URL: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Returns a user delegation key valid at least until {@code neededUntil},
     * fetching a new one only when the cached key is absent or close to expiry.
     */
    private UserDelegationKey delegationKey(OffsetDateTime neededUntil) {
        if (isDelegationKeyUsable(neededUntil)) {
            return delegationKey;
        }
        synchronized (this) {
            if (isDelegationKeyUsable(neededUntil)) {
                return delegationKey;
            }
            OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
            OffsetDateTime start = now.minusMinutes(CLOCK_SKEW_MINUTES);
            OffsetDateTime end = now.plusHours(DELEGATION_KEY_TTL_HOURS);
            if (end.isBefore(neededUntil)) {
                end = neededUntil;
            }
            delegationKey = blobServiceClient.getUserDelegationKey(start, end);
            delegationKeyExpiry = end;
            return delegationKey;
        }
    }

    private boolean isDelegationKeyUsable(OffsetDateTime neededUntil) {
        if (delegationKey == null || delegationKeyExpiry == null) {
            return false;
        }
        OffsetDateTime usableUntil = delegationKeyExpiry.minusMinutes(DELEGATION_KEY_REFRESH_MARGIN_MINUTES);
        return OffsetDateTime.now(ZoneOffset.UTC).isBefore(usableUntil) && !neededUntil.isAfter(delegationKeyExpiry);
    }

    private void checkIfConfigured() {
        if (!configured)
            throw new CustomException("Azure Blob Storage is not configured. Please define AZURE_STORAGE_ACCOUNT and "
                    + "AZURE_STORAGE_CONTAINER in the env variables", HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
