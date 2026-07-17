using System;
using System.Collections.Generic;
using System.IO;
using AxiomPlayground.Modding;
using PP.Core;
using Microsoft.Xna.Framework.Graphics;

namespace PP.Engine;

public sealed class TextureManager
{
    private static readonly TextureManager _instance = new();
    public static TextureManager Instance => _instance;
    private readonly LoggerBaseCore _logger = new();
    private static readonly string SPRITE_FOLDER = "Sprites/";

    // Global texture registry
    // Dictionary<textureId, texture entry>
    private readonly Dictionary<int, TextureEntry> _textures = [];
    // Dictionary<full path, textureId>
    private readonly Dictionary<string, int> _pathToId = new(StringComparer.OrdinalIgnoreCase);
    // Global ID generator
    private int _nextId = 1;

    private TextureManager() { }

    /// <summary>
    /// Registers a texture by modId + path. Returns textureId.
    /// If already loaded, returns existing ID.
    /// </summary>
    public int RegisterTexture(string modId, string sourceModId, string folder, string file)
    {
        var modFolderPath = ModManager.Instance.GetModFolderPath(sourceModId);

        string path = Path.GetFullPath(Path.Combine(
            modFolderPath, SPRITE_FOLDER, folder, file));

        if (_pathToId.TryGetValue(path, out int existingId))
            return existingId;

        // Load texture from file
        if (!File.Exists(path))
            throw new LocalizedErrorCore<FileNotFoundException>("system.textureManager.textureFileNotFound", path);

        using var stream = File.OpenRead(path);
        var texture = Texture2D.FromStream(EngineManager.Instance.GraphicsDevice, stream);

        // Assign ID
        int textureId = _nextId;
        _nextId++;

        _textures[textureId] = new TextureEntry
        {
            RegisterModId = modId,
            Path = path,
            Texture = texture
        };

        _pathToId[path] = textureId;

        _logger.Log("system.textureManager.registered", modId, path, textureId);
        return textureId;
    }

    /// <summary>
    /// Gets a texture by global texture ID.
    /// </summary>
    public bool TryGetTexture(int textureId, out Texture2D texture)
    {
        if (_textures.TryGetValue(textureId, out var entry))
        {
            texture = entry.Texture;
            return true;
        }

        _logger.LogWarning("system.drawManager.textureNotFound", textureId);
        texture = null;
        return false;
    }


    /// <summary>
    /// Gets metadata for a texture.
    /// </summary>
    public bool TryGetTextureInfo(int textureId, out TextureEntry entry)
    {
        return _textures.TryGetValue(textureId, out entry);
    }


    public sealed class TextureEntry
    {
        public string RegisterModId { get; init; } = "";
        public string Path { get; init; } = "";
        public Texture2D Texture { get; init; } = null!;
    }
}