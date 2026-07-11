using AxiomPlayground.Localization;
using AxiomPlayground.Shared;

namespace PP.Core;

public class LoggerBaseCore : LoggerBase
{
    public LoggerBaseCore() : base(ModSystemPolicy.CORE_MOD_ID) { }
}