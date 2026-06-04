package com.coursedrop.server.controller;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;

import com.coursedrop.server.config.ServerProperties;
import com.coursedrop.server.config.StorageProperties;
import com.coursedrop.server.dto.ShareSessionResponse;
import com.coursedrop.server.enums.OwnerIdentityType;
import com.coursedrop.server.mapper.IdentityRepository;
import com.coursedrop.server.service.ShareService;
import com.coursedrop.server.service.WebLoginService;

@Controller
public class HomeController {
    private final StorageProperties storageProperties;
    private final ServerProperties serverProperties;
    private final WebLoginService webLoginService;
    private final ShareService shareService;
    private final IdentityRepository identityRepository;

    public HomeController(
            StorageProperties storageProperties,
            ServerProperties serverProperties,
            WebLoginService webLoginService,
            ShareService shareService,
            IdentityRepository identityRepository) {
        this.storageProperties = storageProperties;
        this.serverProperties = serverProperties;
        this.webLoginService = webLoginService;
        this.shareService = shareService;
        this.identityRepository = identityRepository;
    }

    @GetMapping("/")
    public String home(
            @CookieValue(name = "CD_SESSION", required = false) String cookieToken,
            Model model) {
        model.addAttribute("service", "coursedrop-server");
        model.addAttribute("status", "online");
        model.addAttribute("version", "0.1.0");
        model.addAttribute("checkedAt", Instant.now());
        model.addAttribute("maxFileSizeMb", storageProperties.maxFileSizeMb());
        model.addAttribute("defaultTtlHours", storageProperties.fileTtlHours());
        model.addAttribute("publicBaseUrl", serverProperties.publicBaseUrl());

        var identityOpt = webLoginService.findCookieIdentity(cookieToken);
        if (identityOpt.isPresent()) {
            var identity = identityOpt.get();
            model.addAttribute("isLoggedIn", true);
            model.addAttribute("identity", identity);

            String displayName = "已登录用户";
            List<ShareSessionResponse> myShares = List.of();
            if (identity.accountId() != null) {
                var account = identityRepository.findAccountById(identity.accountId()).orElse(null);
                if (account != null) {
                    displayName = account.getUsername();
                }
                myShares = shareService.listMine(identity.accountId(), OwnerIdentityType.ACCOUNT);
            } else if (identity.fingerprintId() != null) {
                var fingerprint = identityRepository.findFingerprintById(identity.fingerprintId()).orElse(null);
                if (fingerprint != null) {
                    displayName = fingerprint.deviceName();
                }
                myShares = shareService.listMine(identity.fingerprintId(), OwnerIdentityType.FINGERPRINT);
            }
            model.addAttribute("displayName", displayName);
            model.addAttribute("myShares", myShares);
        } else {
            model.addAttribute("isLoggedIn", false);
            var login = webLoginService.create();
            model.addAttribute("login", login);
        }

        return "home";
    }

    @GetMapping("/help")
    public String help(Model model) {
        model.addAttribute("maxFileSizeMb", storageProperties.maxFileSizeMb());
        model.addAttribute("defaultTtlHours", storageProperties.fileTtlHours());
        model.addAttribute("publicBaseUrl", serverProperties.publicBaseUrl());
        return "help";
    }

    @GetMapping("/console")
    public String console(Model model) {
        model.addAttribute("maxFileSizeMb", storageProperties.maxFileSizeMb());
        model.addAttribute("defaultTtlHours", storageProperties.fileTtlHours());
        model.addAttribute("publicBaseUrl", serverProperties.publicBaseUrl());
        return "console";
    }
}

