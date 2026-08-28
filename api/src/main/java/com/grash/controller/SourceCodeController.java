package com.grash.controller;

import io.swagger.v3.oas.annotations.Hidden;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Serves the complete corresponding source code of this running version, as
 * required by the GNU Affero General Public License v3 (AGPLv3) §13.
 * <p>
 * The archive is generated and embedded at build time (see api/Dockerfile,
 * "source" stage) at {@code classpath:/static/source/atlas-cmms-source.zip}.
 * The download is public and unauthenticated so the offer is available to any
 * user who interacts with the application over the network.
 */
@RestController
@RequestMapping("/source-code")
@Hidden
@Slf4j
public class SourceCodeController {

    private static final String BUNDLE_PATH = "static/source/atlas-cmms-source.zip";

    @GetMapping("/download")
    public ResponseEntity<Resource> download() {
        Resource resource = new ClassPathResource(BUNDLE_PATH);
        if (!resource.exists()) {
            log.warn("Source code bundle not found at classpath:{}. " +
                    "Build the API image via api/Dockerfile (repo-root context) to embed it.", BUNDLE_PATH);
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"atlas-cmms-source.zip\"")
                .body(resource);
    }
}
