package com.coursedrop.server.mapper;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.coursedrop.server.entity.TransferItemEntity;
import com.coursedrop.server.dto.TransferItemResponse;
import com.coursedrop.server.transfer.TransferItemStored;
import com.coursedrop.server.enums.TransferItemType;

@Repository
public class TransferItemRepository {
    private final TransferItemMapper mapper;

    public TransferItemRepository(TransferItemMapper mapper) {
        this.mapper = mapper;
    }

    public void save(TransferItemStored item) {
        mapper.insert(toEntity(item));
    }

    public List<TransferItemResponse> findByRoomId(String roomId) {
        return mapper.selectList(new LambdaQueryWrapper<TransferItemEntity>()
                .eq(TransferItemEntity::getRoomId, roomId)
                .ge(TransferItemEntity::getExpiresAt, Instant.now().toString())
                .orderByDesc(TransferItemEntity::getCreatedAt))
                .stream()
                .map(entity -> toResponse(toStored(entity)))
                .toList();
    }

    public Optional<TransferItemStored> findStoredById(String id) {
        return Optional.ofNullable(mapper.selectById(id)).map(this::toStored);
    }

    public List<TransferItemStored> findExpired(Instant now) {
        return mapper.selectList(new LambdaQueryWrapper<TransferItemEntity>()
                .lt(TransferItemEntity::getExpiresAt, now.toString()))
                .stream()
                .map(this::toStored)
                .toList();
    }

    public List<TransferItemStored> findAll() {
        return mapper.selectList(new LambdaQueryWrapper<TransferItemEntity>())
                .stream()
                .map(this::toStored)
                .toList();
    }

    public int deleteExpired(Instant now) {
        return mapper.delete(new LambdaQueryWrapper<TransferItemEntity>()
                .lt(TransferItemEntity::getExpiresAt, now.toString()));
    }

    private TransferItemEntity toEntity(TransferItemStored item) {
        var entity = new TransferItemEntity();
        entity.setId(item.id());
        entity.setRoomId(item.roomId());
        entity.setType(item.type().name());
        entity.setDisplayName(item.displayName());
        entity.setStorageKey(item.storageKey());
        entity.setContentType(item.contentType());
        entity.setSizeBytes(item.sizeBytes());
        entity.setCreatedAt(item.createdAt().toString());
        entity.setExpiresAt(item.expiresAt().toString());
        return entity;
    }

    private TransferItemStored toStored(TransferItemEntity entity) {
        return new TransferItemStored(
                entity.getId(),
                entity.getRoomId(),
                TransferItemType.valueOf(entity.getType()),
                entity.getDisplayName(),
                entity.getStorageKey(),
                entity.getContentType(),
                entity.getSizeBytes(),
                Instant.parse(entity.getCreatedAt()),
                Instant.parse(entity.getExpiresAt()));
    }

    private TransferItemResponse toResponse(TransferItemStored item) {
        return new TransferItemResponse(
                item.id(),
                item.roomId(),
                item.type(),
                item.displayName(),
                item.contentType(),
                item.sizeBytes(),
                item.createdAt(),
                item.expiresAt());
    }
}
