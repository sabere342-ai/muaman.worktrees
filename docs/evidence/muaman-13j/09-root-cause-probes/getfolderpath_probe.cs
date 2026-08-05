using System;
using System.Collections.Generic;
using System.Reflection;
using System.Linq;

public static class GfpProbe
{
    static string AsmPath = @"C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64\Microsoft.Build.Utilities.Core.dll";

    static void RunCase(string label)
    {
        Console.WriteLine("### " + label);
        Console.WriteLine("  APPDATA=[" + Environment.GetEnvironmentVariable("APPDATA") + "]");
        Console.WriteLine("  LOCALAPPDATA=[" + Environment.GetEnvironmentVariable("LOCALAPPDATA") + "]");
        Console.WriteLine("  USERPROFILE=[" + Environment.GetEnvironmentVariable("USERPROFILE") + "]");
        Console.WriteLine("  PROGRAMDATA=[" + Environment.GetEnvironmentVariable("PROGRAMDATA") + "]");
        Console.WriteLine("  TEMP=[" + Environment.GetEnvironmentVariable("TEMP") + "]");
        Console.WriteLine("  GetTempPath=[" + System.IO.Path.GetTempPath() + "]");
        Console.WriteLine("  GFP(ApplicationData)=[" + Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "]");
        Console.WriteLine("  GFP(LocalApplicationData)=[" + Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData) + "]");
        Console.WriteLine("  GFP(CommonApplicationData)=[" + Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData) + "]");
        Console.WriteLine("  GFP(UserProfile)=[" + Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) + "]");
        Console.WriteLine("  GFP(MyDocuments)=[" + Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) + "]");
        Console.WriteLine("  GFP(Desktop)=[" + Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory) + "]");

        var asm = Assembly.LoadFrom(AsmPath);
        var t = asm.GetType("Microsoft.Build.Utilities.FileTracker");
        foreach (var f in t.GetFields(BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public))
        {
            object v = null;
            try { v = f.GetValue(null); } catch (Exception e) { v = "<" + e.GetType().Name + ">"; }
            IEnumerable<string> l = v as IEnumerable<string>;
            if (l != null) Console.WriteLine("  FileTracker." + f.Name + " = [" + string.Join(" | ", l.Select(x => "'" + x + "'")) + "]");
            else Console.WriteLine("  FileTracker." + f.Name + " = [" + v + "]");
        }
        Console.WriteLine();
    }

    static void SetEnv(string name, string value)
    {
        if (value == null) Environment.SetEnvironmentVariable(name, null);
        else Environment.SetEnvironmentVariable(name, value);
    }

    public static int Main(string[] args)
    {
        string BHome = @"C:\dev\muaman-13i-environment-b-independent-home-root";

        SetEnv("APPDATA", BHome + @"\appdata\roaming");
        SetEnv("LOCALAPPDATA", BHome + @"\appdata\local");
        SetEnv("USERPROFILE", BHome);
        SetEnv("PROGRAMDATA", @"");
        SetEnv("TEMP", @"C:\dev\muaman-13i-environment-b-independent-temp-root");
        SetEnv("TMP", @"C:\dev\muaman-13i-environment-b-independent-temp-root");
        RunCase("B-proper (existing dirs)");

        SetEnv("TEMP", @"C:\dev\muaman-13i-environment-b-independent-temp-root-DOES-NOT-EXIST");
        SetEnv("TMP", @"C:\dev\muaman-13i-environment-b-independent-temp-root-DOES-NOT-EXIST");
        RunCase("B temp nonexistent");

        SetEnv("APPDATA", BHome + @"\appdata\roaming-DOES-NOT-EXIST");
        SetEnv("LOCALAPPDATA", BHome + @"\appdata\local-DOES-NOT-EXIST");
        SetEnv("USERPROFILE", BHome + @"-DOES-NOT-EXIST");
        RunCase("B appdata/local/profile nonexistent");

        SetEnv("APPDATA", @"C:\NO-SUCH-DRIVE-Z\roaming");
        SetEnv("LOCALAPPDATA", @"C:\NO-SUCH-DRIVE-Z\local");
        SetEnv("USERPROFILE", @"C:\NO-SUCH-DRIVE-Z");
        RunCase("B appdata on nonexistent drive");

        SetEnv("APPDATA", @"");
        SetEnv("LOCALAPPDATA", @"");
        SetEnv("USERPROFILE", @"");
        SetEnv("PROGRAMDATA", @"");
        SetEnv("TEMP", @"");
        SetEnv("TMP", @"");
        RunCase("all empty string");

        SetEnv("APPDATA", null);
        SetEnv("LOCALAPPDATA", null);
        SetEnv("USERPROFILE", null);
        SetEnv("PROGRAMDATA", null);
        SetEnv("TEMP", null);
        SetEnv("TMP", null);
        RunCase("all unset (null)");

        SetEnv("APPDATA", @".");
        SetEnv("LOCALAPPDATA", @".");
        SetEnv("USERPROFILE", @".");
        SetEnv("PROGRAMDATA", @".");
        SetEnv("TEMP", @".");
        SetEnv("TMP", @".");
        RunCase("all relative dot");

        return 0;
    }
}
