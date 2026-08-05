using System;
using System.Collections.Generic;
using System.Reflection;
using System.Linq;

public static class EmptyStaticProbe
{
    static string AsmPath = @"C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64\Microsoft.Build.Utilities.Core.dll";
    static string TestFile = @"C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app\build\windows\x64\CMakeFiles\4.2.3-msvc3\CompilerIdCXX\CMakeCXXCompilerId.cpp";

    static FieldInfo Field(Type t, string name)
    {
        return t.GetField(name, BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
    }

    public static int Main(string[] args)
    {
        var asm = Assembly.LoadFrom(AsmPath);
        var t = asm.GetType("Microsoft.Build.Utilities.FileTracker");
        var dump = t.GetMethod("DumpState", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var excl = t.GetMethod("FileIsExcludedFromDependencies", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var under = t.GetMethod("FileIsUnderNormalizedPath", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);

        Console.WriteLine("== baseline (all statics from env) ==");
        foreach (var f in t.GetFields(BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public))
        {
            object v = null;
            try { v = f.GetValue(null); } catch (Exception e) { v = "<" + e.GetType().Name + ">"; }
            IEnumerable<string> l = v as IEnumerable<string>;
            if (l != null) Console.WriteLine(f.Name + " = [" + string.Join(", ", l.Select(x => "'" + x + "'")) + "]");
            else Console.WriteLine(f.Name + " = [" + v + "]");
        }
        try { Console.WriteLine("excluded(" + TestFile + ") = " + excl.Invoke(null, new object[] { TestFile })); }
        catch (TargetInvocationException tie) { Console.WriteLine("BASELINE EXCLUDED THREW: " + tie.InnerException); }

        string[] candidates = {
            "s_applicationDataPath",
            "s_localApplicationDataPath",
            "s_localLowApplicationDataPath",
            "s_tempShortPath",
            "s_tempLongPath",
        };
        foreach (var name in candidates)
        {
            var f = Field(t, name);
            var orig = f.GetValue(null);
            f.SetValue(null, "");
            Console.WriteLine("\n== " + name + " set to \"\" ==");
            foreach (string probe in new[] { TestFile, @"C:\Windows\system32\kernel32.dll" })
            {
                try { Console.WriteLine("excluded(" + probe + ") = " + excl.Invoke(null, new object[] { probe })); }
                catch (TargetInvocationException tie) { Console.WriteLine("excluded(" + probe + ") THREW: " + tie.InnerException.GetType().Name + ": " + tie.InnerException.Message); Console.WriteLine(tie.InnerException.StackTrace); }
            }
            f.SetValue(null, orig);
        }

        // common data paths list: set to a list containing an empty string
        var lf = Field(t, "s_commonApplicationDataPaths");
        var lorig = lf.GetValue(null);
        var lst = new List<string> { "" };
        lf.SetValue(null, lst);
        Console.WriteLine("\n== s_commonApplicationDataPaths set to [''] ==");
        try { Console.WriteLine("excluded(" + TestFile + ") = " + excl.Invoke(null, new object[] { TestFile })); }
        catch (TargetInvocationException tie) { Console.WriteLine("excluded THREW: " + tie.InnerException.GetType().Name + ": " + tie.InnerException.Message); Console.WriteLine(tie.InnerException.StackTrace); }
        lf.SetValue(null, lorig);

        return 0;
    }
}
