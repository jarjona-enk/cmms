package com.grash.controller;

import io.swagger.v3.oas.annotations.Hidden;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Serves the React single-page application that is bundled into this jar
 * (frontend build output lives on the classpath under {@code /static}, served
 * at the root by Spring Boot).
 * <p>
 * This controller forwards client-side (deep-link) routes to {@code index.html}
 * so that a browser refresh or direct navigation to a SPA route returns the app
 * shell instead of a 404. REST endpoints are matched first by their own
 * controllers, so only paths with no API mapping reach these forwards.
 */
@Controller
@Hidden
public class SpaForwardController {

    @GetMapping({
            "/app/**",
            "/account/**",
            "/source-code",
            "/payment/**",
            "/request-portal/**",
            "/oauth2/success",
            "/oauth2/failure"
    })
    public String forwardToSpa() {
        return "forward:/index.html";
    }
}
