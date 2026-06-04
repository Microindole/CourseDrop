package com.coursedrop.server.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("group_key_backups")
public class GroupKeyBackupEntity {
    @TableId
    private String id;
    private String accountId;
    private String fingerprintId;
    private String groupId;
    private String algorithm;
    private String kdfAlgorithm;
    private String kdfSalt;
    private String iv;
    private String authTag;
    private String encryptedPayload;
    private String createdAt;
    private String updatedAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getAccountId() {
        return accountId;
    }

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public String getFingerprintId() {
        return fingerprintId;
    }

    public void setFingerprintId(String fingerprintId) {
        this.fingerprintId = fingerprintId;
    }

    public String getGroupId() {
        return groupId;
    }

    public void setGroupId(String groupId) {
        this.groupId = groupId;
    }

    public String getAlgorithm() {
        return algorithm;
    }

    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }

    public String getKdfAlgorithm() {
        return kdfAlgorithm;
    }

    public void setKdfAlgorithm(String kdfAlgorithm) {
        this.kdfAlgorithm = kdfAlgorithm;
    }

    public String getKdfSalt() {
        return kdfSalt;
    }

    public void setKdfSalt(String kdfSalt) {
        this.kdfSalt = kdfSalt;
    }

    public String getIv() {
        return iv;
    }

    public void setIv(String iv) {
        this.iv = iv;
    }

    public String getAuthTag() {
        return authTag;
    }

    public void setAuthTag(String authTag) {
        this.authTag = authTag;
    }

    public String getEncryptedPayload() {
        return encryptedPayload;
    }

    public void setEncryptedPayload(String encryptedPayload) {
        this.encryptedPayload = encryptedPayload;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }
}
