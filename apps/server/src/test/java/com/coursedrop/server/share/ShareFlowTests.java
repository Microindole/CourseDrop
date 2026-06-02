package com.coursedrop.server.share;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.coursedrop.server.mapper.ShareItemRepository;

@SpringBootTest
@AutoConfigureMockMvc
class ShareFlowTests {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ShareItemRepository shareItemRepository;

    @Test
    void homePageRendersServerEntry() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("CourseDrop / 课递")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("/api/health")));
    }

    @Test
    void shareCanUploadAndDownloadThroughAppEndpoint() throws Exception {
        var fingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "test-device-share-flow",
                          "deviceName": "Test Phone",
                          "platform": "HarmonyOS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        var fingerprintId = objectMapper.readTree(fingerprintResult.getResponse().getContentAsString()).get("id")
                .asText();

        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "OWNER_ONLY",
                          "ownerIdentityId": "%s",
                          "ownerIdentityType": "FINGERPRINT"
                        }
                        """.formatted(fingerprintId)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();
        var code = share.get("code").asText();
        assertThat(share.get("downloadUrl").asText()).isEqualTo("/s/" + code);
        assertThat(share.get("downloadPolicy").asText()).isEqualTo("OWNER_ONLY");

        var file = new MockMultipartFile(
                "file",
                "hello.txt",
                "text/plain",
                "hello coursedrop".getBytes());
        var uploadResult = mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId)
                .file(file)
                .param("encrypted", "false")
                .param("sha256", "sample"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode item = objectMapper.readTree(uploadResult.getResponse().getContentAsString());
        var itemId = item.get("id").asText();

        mockMvc.perform(get("/api/shares/{code}", code))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/shares/{code}/items/{itemId}/download", code, itemId)
                .header("X-CourseDrop-Fingerprint-Id", fingerprintId))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename*=UTF-8''hello.txt"));
    }

    @Test
    void publicBrowserDownloadDoesNotRequireAuthorization() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "PUBLIC",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();
        var code = share.get("code").asText();

        var file = new MockMultipartFile("file", "locked.txt", "text/plain", "locked".getBytes());
        var uploadResult = mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId).file(file))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode item = objectMapper.readTree(uploadResult.getResponse().getContentAsString());
        var itemId = item.get("id").asText();

        mockMvc.perform(get("/s/{code}/items/{itemId}/download", code, itemId))
                .andExpect(status().isOk());
    }

    @Test
    void browserDownloadPageRendersUploadedItems() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "PUBLIC",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();
        var code = share.get("code").asText();

        var file = new MockMultipartFile("file", "google邮箱.txt", "text/plain", "hello browser".getBytes());
        mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId).file(file))
                .andExpect(status().isOk());

        mockMvc.perform(get("/s/{code}", code))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("google邮箱.txt")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("download-link")));
    }

    @Test
    void uploadedStorageKeyDoesNotExposeOriginalFilename() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "PUBLIC",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();

        var file = new MockMultipartFile("file", "private-course-plan.txt", "text/plain", "secret".getBytes());
        var uploadResult = mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId).file(file))
                .andExpect(status().isOk())
                .andReturn();
        var itemId = objectMapper.readTree(uploadResult.getResponse().getContentAsString()).get("id").asText();

        var item = shareItemRepository.findById(itemId).orElseThrow();
        assertThat(item.storageKey()).doesNotContain("private-course-plan");
        assertThat(item.storageKey()).doesNotContain(".txt");
        assertThat(item.storageKey()).contains("/");
    }

    @Test
    void loginRequiredBrowserDownloadRequiresAuthorizationHeader() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "LOGIN_REQUIRED",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();
        var code = share.get("code").asText();

        var file = new MockMultipartFile("file", "locked.txt", "text/plain", "locked".getBytes());
        var uploadResult = mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId).file(file))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode item = objectMapper.readTree(uploadResult.getResponse().getContentAsString());
        var itemId = item.get("id").asText();

        mockMvc.perform(get("/s/{code}/items/{itemId}/download", code, itemId))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/s/{code}/items/{itemId}/download", code, itemId)
                .header("X-CourseDrop-Web-Authorized", "true"))
                .andExpect(status().isOk());
    }

    @Test
    void browserDownloadPageRendersTailwindLoginSurface() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "LOGIN_REQUIRED",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        var code = objectMapper.readTree(createResult.getResponse().getContentAsString()).get("code").asText();

        mockMvc.perform(get("/s/{code}", code))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("https://cdn.tailwindcss.com")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("登录并下载到电脑")));
    }

    @Test
    void encryptedUploadRequiresCompleteMetadata() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "PUBLIC",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        var shareId = objectMapper.readTree(createResult.getResponse().getContentAsString()).get("id").asText();
        var file = new MockMultipartFile("file", "encrypted.bin", "application/octet-stream", "cipher".getBytes());

        mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId)
                .file(file)
                .param("encrypted", "true"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void encryptedUploadAllowsRawKeyWithoutKdfSalt() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "PUBLIC",
                          "ownerIdentityType": "ANONYMOUS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        var share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();
        var code = share.get("code").asText();
        var file = new MockMultipartFile("file", "encrypted.bin", "application/octet-stream", "cipher".getBytes());

        mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId)
                .file(file)
                .param("encrypted", "true")
                .param("encryptionAlgorithm", "AES-256-GCM")
                .param("kdfAlgorithm", "NONE-RAW-KEY")
                .param("nonce", "00112233445566778899aabb.ccddeeff00112233445566778899aabb")
                .param("sha256", "0123456789abcdef")
                .param("plainSizeBytes", "6"))
                .andExpect(status().isOk());

        var pageResult = mockMvc.perform(get("/api/shares/{code}", code))
                .andExpect(status().isOk())
                .andReturn();
        var page = objectMapper.readTree(pageResult.getResponse().getContentAsString());
        assertThat(page.get("items")).hasSize(1);
    }

    @Test
    void webLoginConfirmationIssuesCookie() throws Exception {
        var fingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "test-device-web-login",
                          "deviceName": "Login Phone",
                          "platform": "HarmonyOS"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        var fingerprintId = objectMapper.readTree(fingerprintResult.getResponse().getContentAsString()).get("id")
                .asText();

        var createLogin = mockMvc.perform(post("/api/auth/web-login"))
                .andExpect(status().isOk())
                .andReturn();
        var loginCode = objectMapper.readTree(createLogin.getResponse().getContentAsString()).get("loginCode").asText();

        mockMvc.perform(post("/api/auth/web-login/{loginCode}/confirm", loginCode)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprintId": "%s"
                        }
                        """.formatted(fingerprintId)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/auth/web-login/{loginCode}", loginCode))
                .andExpect(status().isOk())
                .andExpect(header().exists(HttpHeaders.SET_COOKIE));
    }

    @Test
    void mobileLoginPageCanConfirmWebLogin() throws Exception {
        var suffix = Long.toString(System.nanoTime());
        var fingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "test-device-mobile-login-%s",
                          "deviceName": "Android Browser",
                          "platform": "Android"
                        }
                        """.formatted(suffix)))
                .andExpect(status().isOk())
                .andReturn();
        var fingerprintId = objectMapper.readTree(fingerprintResult.getResponse().getContentAsString()).get("id")
                .asText();

        var createLogin = mockMvc.perform(post("/api/auth/web-login"))
                .andExpect(status().isOk())
                .andReturn();
        var loginCode = objectMapper.readTree(createLogin.getResponse().getContentAsString()).get("loginCode").asText();

        mockMvc.perform(get("/api/auth/web-login/{loginCode}/qr.svg", loginCode))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("image/svg+xml"));

        mockMvc.perform(get("/m/login/{loginCode}", loginCode))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("确认网页登录")));

        mockMvc.perform(post("/m/login/{loginCode}", loginCode)
                .param("fingerprintId", fingerprintId))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("已确认登录")));

        mockMvc.perform(get("/api/auth/web-login/{loginCode}", loginCode))
                .andExpect(status().isOk())
                .andExpect(header().exists(HttpHeaders.SET_COOKIE));
    }

    @Test
    void accountSecurityAndDeviceBindingCanBeManaged() throws Exception {
        var suffix = Long.toString(System.nanoTime());
        var primaryFingerprint = "test-device-account-primary-" + suffix;
        var secondaryFingerprint = "test-device-account-secondary-" + suffix;
        var username = "test-account-security-" + suffix;

        var firstFingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "%s",
                          "deviceName": "Primary Phone",
                          "platform": "HarmonyOS"
                        }
                        """.formatted(primaryFingerprint)))
                .andExpect(status().isOk())
                .andReturn();
        var firstFingerprintId = objectMapper.readTree(firstFingerprintResult.getResponse().getContentAsString())
                .get("id").asText();

        var accountResult = mockMvc.perform(post("/api/accounts")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "old-secret",
                          "fingerprintId": "%s",
                          "passwordLoginEnabled": false
                        }
                        """.formatted(username, firstFingerprintId)))
                .andExpect(status().isOk())
                .andReturn();
        var accountId = objectMapper.readTree(accountResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(post("/api/auth/web-login/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "old-secret"
                        }
                        """.formatted(username)))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/accounts/{accountId}/security", accountId)
                .header("X-CourseDrop-Fingerprint-Id", firstFingerprintId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "passwordLoginEnabled": true
                        }
                        """))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"passwordLoginEnabled\":true")));

        mockMvc.perform(post("/api/accounts/{accountId}/password", accountId)
                .header("X-CourseDrop-Fingerprint-Id", firstFingerprintId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "password": "new-secret"
                        }
                        """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/web-login/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "new-secret"
                        }
                        """.formatted(username)))
                .andExpect(status().isOk())
                .andExpect(header().exists(HttpHeaders.SET_COOKIE));

        var secondFingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "%s",
                          "deviceName": "Tablet",
                          "platform": "HarmonyOS"
                        }
                        """.formatted(secondaryFingerprint)))
                .andExpect(status().isOk())
                .andReturn();
        var secondFingerprintId = objectMapper.readTree(secondFingerprintResult.getResponse().getContentAsString())
                .get("id").asText();

        mockMvc.perform(post("/api/accounts/{accountId}/fingerprints", accountId)
                .header("X-CourseDrop-Fingerprint-Id", firstFingerprintId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprintId": "%s"
                        }
                        """.formatted(secondFingerprintId)))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString(accountId)));

        mockMvc.perform(get("/api/accounts/{accountId}/fingerprints", accountId)
                .header("X-CourseDrop-Fingerprint-Id", firstFingerprintId))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Tablet")));

        mockMvc.perform(delete("/api/accounts/{accountId}/fingerprints/{fingerprintId}", accountId, secondFingerprintId)
                .header("X-CourseDrop-Fingerprint-Id", firstFingerprintId))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/accounts/{accountId}/fingerprints", accountId))
                .andExpect(status().isForbidden());
    }

    @Test
    void appCanLoginExistingAccountAndBindCurrentFingerprint() throws Exception {
        var suffix = Long.toString(System.nanoTime());
        var primaryFingerprint = "test-device-account-login-primary-" + suffix;
        var secondaryFingerprint = "test-device-account-login-secondary-" + suffix;
        var username = "test-account-login-" + suffix;

        var firstFingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "%s",
                          "deviceName": "Primary Phone",
                          "platform": "HarmonyOS"
                        }
                        """.formatted(primaryFingerprint)))
                .andExpect(status().isOk())
                .andReturn();
        var firstFingerprintId = objectMapper.readTree(firstFingerprintResult.getResponse().getContentAsString())
                .get("id").asText();

        var accountResult = mockMvc.perform(post("/api/accounts")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "login-secret",
                          "fingerprintId": "%s",
                          "passwordLoginEnabled": false
                        }
                        """.formatted(username, firstFingerprintId)))
                .andExpect(status().isOk())
                .andReturn();
        var accountId = objectMapper.readTree(accountResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(post("/api/accounts")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "login-secret",
                          "fingerprintId": "%s",
                          "passwordLoginEnabled": true
                        }
                        """.formatted(username, firstFingerprintId)))
                .andExpect(status().isConflict());

        var secondFingerprintResult = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "%s",
                          "deviceName": "Second Phone",
                          "platform": "HarmonyOS"
                        }
                        """.formatted(secondaryFingerprint)))
                .andExpect(status().isOk())
                .andReturn();
        var secondFingerprintId = objectMapper.readTree(secondFingerprintResult.getResponse().getContentAsString())
                .get("id").asText();

        mockMvc.perform(post("/api/accounts/{accountId}/security", accountId)
                .header("X-CourseDrop-Fingerprint-Id", firstFingerprintId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "passwordLoginEnabled": true
                        }
                        """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/accounts/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "wrong-secret",
                          "fingerprintId": "%s"
                        }
                        """.formatted(username, secondFingerprintId)))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/accounts/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "username": "%s",
                          "password": "login-secret",
                          "fingerprintId": "%s"
                        }
                        """.formatted(username, secondFingerprintId)))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString(accountId)))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"passwordLoginEnabled\":true")));

        mockMvc.perform(get("/api/accounts/{accountId}/fingerprints", accountId)
                .header("X-CourseDrop-Fingerprint-Id", secondFingerprintId))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Second Phone")));
    }

    @Test
    void shareCanBeExtendedAndItemCanBeDeleted() throws Exception {
        var createResult = mockMvc.perform(post("/api/shares")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 1,
                          "downloadPolicy": "PUBLIC",
                          "ownerIdentityId": "owner-1",
                          "ownerIdentityType": "FINGERPRINT"
                        }
                        """))
                .andExpect(status().isOk())
                .andReturn();
        var share = objectMapper.readTree(createResult.getResponse().getContentAsString());
        var shareId = share.get("id").asText();

        mockMvc.perform(post("/api/shares/{shareId}/expiry", shareId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "expireHours": 2
                        }
                        """))
                .andExpect(status().isOk());

        var file = new MockMultipartFile("file", "remove.txt", "text/plain", "remove".getBytes());
        var uploadResult = mockMvc.perform(multipart("/api/shares/{shareId}/items", shareId).file(file))
                .andExpect(status().isOk())
                .andReturn();
        var itemId = objectMapper.readTree(uploadResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(delete("/api/shares/{shareId}/items/{itemId}", shareId, itemId)
                .header("X-CourseDrop-Fingerprint-Id", "owner-1"))
                .andExpect(status().isNoContent());
    }
}
