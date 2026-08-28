package com.grash.configuration;

import com.grash.security.OAuth2Properties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.oauth2.client.CommonOAuth2Provider;
import org.springframework.security.oauth2.client.registration.ClientRegistration;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.registration.InMemoryClientRegistrationRepository;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;

@Configuration
@ConditionalOnProperty(name = "enable-sso", havingValue = "true")
public class OAuth2ClientRegistrationConfig {

    public enum Oauth2Provider {GOOGLE, MICROSOFT}

    @Value("${api.host}")
    private String PUBLIC_API_URL;

    @Bean
    public ClientRegistrationRepository clientRegistrationRepository(OAuth2Properties properties) {
        Oauth2Provider provider = Oauth2Provider.valueOf(properties.getProvider().toUpperCase());

        ClientRegistration registration;
        String clientId = System.getenv("OAUTH2_CLIENT_ID");
        String clientSecret = System.getenv("OAUTH2_CLIENT_SECRET");
        // Entra authority segment. Single-tenant app registrations reject the
        // /common endpoint (AADSTS50194), so allow pinning to a specific tenant
        // id. Defaults to "common" (multi-tenant) to preserve prior behaviour.
        String tenant = System.getenv("OAUTH2_TENANT_ID");
        if (tenant == null || tenant.isBlank()) {
            tenant = "common";
        }
        registration = switch (provider) {
            case GOOGLE -> CommonOAuth2Provider.GOOGLE
                    .getBuilder("google")
                    .clientId(clientId)
                    .clientSecret(clientSecret)
                    .redirectUri(PUBLIC_API_URL + "/oauth2/callback/{registrationId}")
                    .scope("email", "profile")
                    .build();
            case MICROSOFT -> ClientRegistration.withRegistrationId("microsoft")
                    .clientId(clientId)
                    .clientSecret(clientSecret)
                    .redirectUri(PUBLIC_API_URL + "/oauth2/callback/{registrationId}")
                    .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                    .clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_POST)
                    .scope("email", "profile", "openid")
                    .authorizationUri("https://login.microsoftonline.com/" + tenant + "/oauth2/v2.0/authorize")
                    .tokenUri("https://login.microsoftonline.com/" + tenant + "/oauth2/v2.0/token")
                    .jwkSetUri("https://login.microsoftonline.com/" + tenant + "/discovery/v2.0/keys")
                    .userInfoUri("https://graph.microsoft.com/oidc/userinfo")
                    .userNameAttributeName("sub")
                    .build();
            default -> throw new IllegalArgumentException("Unsupported provider: " + provider);
        };
        return new InMemoryClientRegistrationRepository(registration);
    }
}
