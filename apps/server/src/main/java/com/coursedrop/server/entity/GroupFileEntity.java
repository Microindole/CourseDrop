package com.coursedrop.server.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("group_files")
public class GroupFileEntity {
    @TableId
    private String id;
    private String groupId;
    private String uploaderId;
    private String storageKey;
    private String contentType;
    private Long sizeBytes;
    private Integer encrypted;
    private String encryptionAlgorithm;
    private String kdfAlgorithm;
    private String kdfSalt;
    private String nonce;
    private String sha256;
    private Long plainSizeBytes;
    private String createdAt;
    private String expiresAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getGroupId() {
        return groupId;
    }

    public void setGroupId(String groupId) {
        this.groupId = groupId;
    }

    public String getUploaderId() {
        return uploaderId;
    }

    public void setUploaderId(String uploaderId) {
        this.uploaderId = uploaderId;
    }

    public String getStorageKey() {
        return storageKey;
    }

    public void setStorageKey(String storageKey) {
        this.storageKey = storageKey;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public Long getSizeBytes() {
        return sizeBytes;
    }

    public void setSizeBytes(Long sizeBytes) {
        this.sizeBytes = sizeBytes;
    }

    public Integer getEncrypted() {
        return encrypted;
    }

    public void setEncrypted(Integer encrypted) {
        this.encrypted = encrypted;
    }

    public String getEncryptionAlgorithm() {
        return encryptionAlgorithm;
    }

    public void setEncryptionAlgorithm(String encryptionAlgorithm) {
        this.encryptionAlgorithm = encryptionAlgorithm;
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

    public String getNonce() {
        return nonce;
    }

    public void setNonce(String nonce) {
        this.nonce = nonce;
    }

    public String getSha256() {
        return sha256;
    }

    public void setSha256(String sha256) {
        this.sha256 = sha256;
    }

    public Long getPlainSizeBytes() {
        return plainSizeBytes;
    }

    public void setPlainSizeBytes(Long plainSizeBytes) {
        this.plainSizeBytes = plainSizeBytes;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(String expiresAt) {
        this.expiresAt = expiresAt;
    }
}
