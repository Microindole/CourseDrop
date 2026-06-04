package com.coursedrop.server.group;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
class GroupFlowTests {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void groupCanCreateJoinSendAndSyncEncryptedMessages() throws Exception {
        var suffix = Long.toString(System.nanoTime());
        var ownerFingerprintId = registerFingerprint("owner-" + suffix, "Owner Phone");
        var memberFingerprintId = registerFingerprint("member-" + suffix, "Member Phone");

        var createGroupResult = mockMvc.perform(post("/api/groups")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "encryptedName": "cipher-name",
                          "nameIv": "name-iv",
                          "nameAuthTag": "name-tag",
                          "creatorId": "%s",
                          "configJson": "{\\"allowText\\":false,\\"expiryHours\\":24,\\"maxFileSizeMb\\":100}"
                        }
                        """.formatted(ownerFingerprintId)))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("cipher-name")))
                .andReturn();
        var groupId = objectMapper.readTree(createGroupResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(get("/api/groups/mine")
                .header("X-CourseDrop-Fingerprint-Id", ownerFingerprintId))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString(groupId)))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"role\":\"OWNER\"")));

        mockMvc.perform(post("/api/groups/{groupId}/join", groupId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprintId": "%s"
                        }
                        """.formatted(memberFingerprintId)))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"role\":\"MEMBER\"")));

        mockMvc.perform(post("/api/groups/{groupId}/messages", groupId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "id": "message-%s",
                          "senderId": "%s",
                          "type": "FILE",
                          "iv": "payload-iv",
                          "authTag": "payload-tag",
                          "encryptedPayload": "payload-cipher"
                        }
                        """.formatted(suffix, ownerFingerprintId)))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("payload-cipher")));

        mockMvc.perform(get("/api/groups/{groupId}/messages", groupId)
                .header("X-CourseDrop-Fingerprint-Id", memberFingerprintId))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("payload-cipher")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("nextCursor")));

        var encryptedFile = new MockMultipartFile(
                "file",
                "cipher.bin",
                "application/octet-stream",
                "ciphertext".getBytes());
        var uploadResult = mockMvc.perform(multipart("/api/groups/{groupId}/files", groupId)
                .file(encryptedFile)
                .header("X-CourseDrop-Fingerprint-Id", ownerFingerprintId)
                .param("encrypted", "true")
                .param("encryptionAlgorithm", "AES-256-GCM")
                .param("kdfAlgorithm", "NONE-RAW-KEY")
                .param("nonce", "00112233445566778899aabb.ccddeeff00112233445566778899aabb")
                .param("sha256", "0123456789abcdef")
                .param("plainSizeBytes", "9")
                .param("expiryHours", "1"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"encrypted\":true")))
                .andReturn();
        var fileId = objectMapper.readTree(uploadResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(get("/api/groups/{groupId}/files/{fileId}/download", groupId, fileId)
                .header("X-CourseDrop-Fingerprint-Id", memberFingerprintId))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename*=UTF-8''group-file-" + fileId + ".bin"));

        var outsiderFingerprintId = registerFingerprint("outsider-" + suffix, "Outsider Phone");
        mockMvc.perform(get("/api/groups/{groupId}/files/{fileId}/download", groupId, fileId)
                .header("X-CourseDrop-Fingerprint-Id", outsiderFingerprintId))
                .andExpect(status().isForbidden());
    }

    @Test
    void encryptedGroupFileRequiresCompleteMetadata() throws Exception {
        var suffix = Long.toString(System.nanoTime());
        var ownerFingerprintId = registerFingerprint("owner-metadata-" + suffix, "Owner Phone");
        var groupId = createGroup(ownerFingerprintId, suffix);
        var encryptedFile = new MockMultipartFile(
                "file",
                "cipher.bin",
                "application/octet-stream",
                "ciphertext".getBytes());

        mockMvc.perform(multipart("/api/groups/{groupId}/files", groupId)
                .file(encryptedFile)
                .header("X-CourseDrop-Fingerprint-Id", ownerFingerprintId)
                .param("encrypted", "true"))
                .andExpect(status().isBadRequest());
    }

    private String registerFingerprint(String fingerprint, String deviceName) throws Exception {
        var result = mockMvc.perform(post("/api/identity/fingerprints")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "fingerprint": "%s",
                          "deviceName": "%s",
                          "platform": "HarmonyOS"
                        }
                        """.formatted(fingerprint, deviceName)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText();
    }

    private String createGroup(String ownerFingerprintId, String suffix) throws Exception {
        var createGroupResult = mockMvc.perform(post("/api/groups")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "encryptedName": "cipher-name-%s",
                          "nameIv": "name-iv",
                          "nameAuthTag": "name-tag",
                          "creatorId": "%s",
                          "configJson": "{\\"allowText\\":false,\\"expiryHours\\":24,\\"maxFileSizeMb\\":100}"
                        }
                        """.formatted(suffix, ownerFingerprintId)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(createGroupResult.getResponse().getContentAsString()).get("id").asText();
    }
}
