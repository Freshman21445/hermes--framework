//! AES-256-GCM encryption/decryption for agent-server communication.
//! Uses Zig's std.crypto.aead.gcm.

const std = @import("std");
const aead = std.crypto.aead.gcm;
const Allocator = std.mem.Allocator;

pub const Key = [32]u8;
pub const Nonce = [12]u8;
pub const TagLength = aead.tag_length;

/// Encrypt plaintext with AES-256-GCM. Returns ciphertext prefixed with nonce.
pub fn encrypt(plaintext: []const u8, key: Key, allocator: Allocator) ![]u8 {
    var nonce: Nonce = undefined;
    std.crypto.random.bytes(&nonce);

    const ciphertext_len = plaintext.len + TagLength;
    var out = try allocator.alloc(u8, nonce.len + ciphertext_len);
    @memcpy(out[0..nonce.len], &nonce);

    aead.encrypt(
        out[nonce.len..],
        plaintext,
        &nonce,
        key,
        null, // no AAD
    ) catch return error.EncryptionFailed;

    return out;
}

/// Decrypt ciphertext (nonce || ciphertext+tag). Returns plaintext.
pub fn decrypt(data: []const u8, key: Key, allocator: Allocator) ![]u8 {
    if (data.len < Nonce.len + TagLength) return error.InvalidCiphertext;

    const nonce = data[0..Nonce.len];
    const ct = data[Nonce.len..];

    const plaintext_len = ct.len - TagLength;
    var out = try allocator.alloc(u8, plaintext_len);

    aead.decrypt(
        out,
        ct,
        nonce,
        key,
        null,
    ) catch return error.DecryptionFailed;

    return out;
}

/// Convert session key from base64 string to Key.
pub fn keyFromBase64(b64: []const u8) !Key {
    var key: Key = undefined;
    const decoder = std.base64.standard.Decoder;
    const size = try decoder.calcSizeForSlice(b64);
    if (size != key.len) return error.InvalidKeyLength;
    try decoder.decode(&key, b64);
    return key;
}

/// Encode key to base64 string.
pub fn keyToBase64(key: Key, allocator: Allocator) ![]u8 {
    const encoder = std.base64.standard.Encoder;
    const size = encoder.calcSize(key.len);
    var out = try allocator.alloc(u8, size);
    _ = encoder.encode(out, &key);
    return out;
}
