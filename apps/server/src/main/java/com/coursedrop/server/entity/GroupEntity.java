package com.coursedrop.server.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("group_sessions")
public class GroupEntity {
    @TableId
    private String id;
    private String encryptedName;
    private String nameIv;
    private String nameAuthTag;
    private String creatorId;
    private String status;
    private String configJson;
    private String createdAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getEncryptedName() {
        return encryptedName;
    }

    public void setEncryptedName(String encryptedName) {
        this.encryptedName = encryptedName;
    }

    public String getNameIv() {
        return nameIv;
    }

    public void setNameIv(String nameIv) {
        this.nameIv = nameIv;
    }

    public String getNameAuthTag() {
        return nameAuthTag;
    }

    public void setNameAuthTag(String nameAuthTag) {
        this.nameAuthTag = nameAuthTag;
    }

    public String getCreatorId() {
        return creatorId;
    }

    public void setCreatorId(String creatorId) {
        this.creatorId = creatorId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getConfigJson() {
        return configJson;
    }

    public void setConfigJson(String configJson) {
        this.configJson = configJson;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
