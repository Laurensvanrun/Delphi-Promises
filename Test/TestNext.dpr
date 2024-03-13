// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
program TestNext;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  Next.Core.DisposableValue in '..\Core\Types\Next.Core.DisposableValue.pas',
  Next.Core.FailureReason in '..\Core\Types\Next.Core.FailureReason.pas',
  Next.Core.Promises in '..\Core\Types\Next.Core.Promises.pas',
  Next.Core.TTry in '..\Core\Types\Next.Core.TTry.pas',
  Next.Core.Void in '..\Core\Types\Next.Core.Void.pas',
  Next.Core.Test.Assert in 'Next.Core.Test.Assert.pas',
  Next.Core.TestDisposableValue in 'Types\Next.Core.TestDisposableValue.pas',
  Next.Core.TestFailureReason in 'Types\Next.Core.TestFailureReason.pas',
  Next.Core.TestPromises in 'Types\Next.Core.TestPromises.pas',
  Next.Core.TestVoid in 'Types\Next.Core.TestVoid.pas',
  Next.Core.Test.GenericTest in 'Next.Core.Test.GenericTest.pas',
  Next.Core.TestTry in 'Types\Next.Core.TestTry.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
  ReportMemoryLeaksOnShutdown := True;
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
