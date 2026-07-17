using System;
using System.Collections.Generic;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;
using static PP.Engine.DrawManager;

namespace PP.Engine.LuaBindings;

public sealed class DrawLuaBinding : LuaBindingBase
{
    private static readonly Dictionary<string, DrawRequestType> RequestTypes =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["sprite"] = DrawRequestType.Sprite,
            ["rectangle"] = DrawRequestType.Rectangle
        };

    private static readonly Dictionary<string, ReservedField> ReservedFields =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["x"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 0f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.X = (float)v
            },

            ["y"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 0f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.Y = (float)v
            },

            ["rotation"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 0f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.Rotation = (float)v
            },

            ["scaleX"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 1f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.ScaleX = (float)v
            },

            ["scaleY"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 1f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.ScaleY = (float)v
            },

            ["pivotX"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 0f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.PivotX = (float)v
            },

            ["pivotY"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 0f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.PivotY = (float)v
            },

            ["layerDepth"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = 0f,
                Parse = d => Convert.ToSingle(d.Number),
                Assign = (r, v) => r.LayerDepth = (float)v
            },
            ["r"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = (byte)255,
                Parse = d => Convert.ToByte(d.Number),
                Assign = (r, v) => r.R = (byte)v
            },

            ["g"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = (byte)255,
                Parse = d => Convert.ToByte(d.Number),
                Assign = (r, v) => r.G = (byte)v
            },

            ["b"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = (byte)255,
                Parse = d => Convert.ToByte(d.Number),
                Assign = (r, v) => r.B = (byte)v
            },

            ["a"] = new()
            {
                HasDefaultValue = true,
                DefaultValue = (byte)255,
                Parse = d => Convert.ToByte(d.Number),
                Assign = (r, v) => r.A = (byte)v
            }
        };

    private static readonly HashSet<string> IgnoredFields =
        [
            "type"
        ];

    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);

        Table drawTable = new(luaScript);

        drawTable["AddRequest"] = (Action<DynValue>)(requestDyn =>
        {
            if (requestDyn.Type != DataType.Table)
            {
                throw new ScriptRuntimeException("[DrawLuaBinding] AddRequest expects a table.");
            }

            Table table = requestDyn.Table;

            DrawRequest request = new()
            {
                Type = ParseRequestType(table.Get("type"))
            };

            foreach (var field in ReservedFields)
            {
                DynValue dyn = table.Get(field.Key);

                object value;

                if (dyn.IsNil())
                {
                    if (!field.Value.HasDefaultValue)
                    {
                        throw new ScriptRuntimeException($"[DrawLuaBinding] Required draw field is missing: {field.Key}.");
                    }

                    value = field.Value.DefaultValue!;
                }
                else
                {
                    value = field.Value.Parse(dyn);
                }

                field.Value.Assign(request, value);
            }

            foreach (TablePair pair in table.Pairs)
            {
                string key = pair.Key.CastToString();

                if (IgnoredFields.Contains(key))
                    continue;

                if (ReservedFields.ContainsKey(key))
                    continue;

                request.Data[key] = pair.Value.ToObject();
            }

            DrawManager.Instance.AddRequest(request);
        });

        luaScript.Globals["Drawing"] = drawTable;
    }

    private static DrawRequestType ParseRequestType(DynValue value)
    {
        if (value.IsNil())
        {
            throw new ScriptRuntimeException("[DrawLuaBinding] Draw request type is missing or invalid.");
        }

        string type = value.CastToString();

        if (RequestTypes.TryGetValue(type, out var requestType))
        {
            return requestType;
        }

        throw new ScriptRuntimeException($"[DrawLuaBinding] Unknown draw request type: {type}");
    }

    private sealed class ReservedField
    {
        /// <summary>
        /// Default value to use when the field is omitted.
        /// Null means the field is required.
        /// </summary>
        public object DefaultValue { get; init; }
        public bool HasDefaultValue { get; init; }

        /// <summary>
        /// Converts a Lua value into the desired CLR value.
        /// </summary>
        public required Func<DynValue, object> Parse { get; init; }

        /// <summary>
        /// Assigns the parsed value to the DrawRequest.
        /// Null means the field is consumed elsewhere (e.g. r/g/b/a).
        /// </summary>
        public required Action<DrawRequest, object> Assign { get; init; }
    }
}