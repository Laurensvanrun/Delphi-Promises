unit TestPromiseAny;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.SyncObjs, System.Classes,
  Next.Core.Promises, Next.Core.Promises.Exceptions, Next.Core.Test.Assert,
  Next.Core.Test.GenericTest, Next.Core.TestPromises;

type
  [TestFixture]
  TTestPromiseAny<T> = class(TGenericTest<T>)
  public
    [Test]    procedure EmptyArrayRejects;
    [Test]    procedure SingleResolvingPromise;
    [Test]    procedure SingleRejectingPromise;
    [Test]    procedure FirstResolvesAnyResolves;
    [Test]    procedure OnlyLastResolvesStillResolves;
    [Test]    procedure AllRejectAggregateException;
    [Test]    procedure AllRejectExceptionCountMatches;
    [Test]
    procedure AllRejectMessagesPreserved;
  end;

  [TestFixture]
  TTestPromiseAnyConcurrency = class
  public
    [Test]    procedure StressTestManyPromises;
  end;

implementation

{ TTestPromiseAny<T> }

procedure TTestPromiseAny<T>.EmptyArrayRejects;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([]);
  Assert.RejectsWith(LPromise, EArgumentException);
end;

procedure TTestPromiseAny<T>.SingleResolvingPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([
    Promise.Resolve<T>(function: T
      begin
        Result := CreateValue(7);
      end)
  ]);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(7), LPromise.Await);
end;

procedure TTestPromiseAny<T>.SingleRejectingPromise;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([
    Promise.Reject<T>(ETestException.Create('only error'))
  ]);

  Assert.RejectsWith(LPromise, EAggregateException);

  LPromise.InternalWait;
  var LAgg := LPromise.GetFailure.Reason as EAggregateException;
  Assert.AreEqual(1, Length(LAgg.Exceptions));
  Assert.IsTrue(LAgg.Message.Contains('only error'));
end;

procedure TTestPromiseAny<T>.FirstResolvesAnyResolves;
var
  LPromise: IPromise<T>;
  LSlowSignal: TEvent;
begin
  LSlowSignal := TEvent.Create;
  try
    LPromise := Promise.Any<T>([
      Promise.Reject<T>(ETestException.Create('error1')),
      Promise.Resolve<T>(function: T
        begin
          Result := CreateValue(42);
        end),
      Promise.Resolve<T>(function: T
        begin
          LSlowSignal.WaitFor;
          Result := CreateValue(99);
        end)
    ]);

    Assert.Resolves(LPromise);
    TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
    LSlowSignal.SetEvent;
  finally
    LSlowSignal.Free;
  end;
end;

procedure TTestPromiseAny<T>.OnlyLastResolvesStillResolves;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([
    Promise.Reject<T>(ETestException.Create('error1')),
    Promise.Reject<T>(ETestException.Create('error2')),
    Promise.Resolve<T>(function: T
      begin
        Sleep(50);
        Result := CreateValue(42);
      end)
  ]);

  Assert.Resolves(LPromise);
  TestEqualsFreeExpected(CreateValue(42), LPromise.Await);
end;

procedure TTestPromiseAny<T>.AllRejectAggregateException;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([
    Promise.Reject<T>(ETestException.Create('error1')),
    Promise.Reject<T>(ETestException.Create('error2')),
    Promise.Reject<T>(ETestException.Create('error3'))
  ]);

  Assert.RejectsWith(LPromise, EAggregateException);
end;

procedure TTestPromiseAny<T>.AllRejectExceptionCountMatches;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([
    Promise.Reject<T>(ETestException.Create('e1')),
    Promise.Reject<T>(ETestException.Create('e2')),
    Promise.Reject<T>(ETestException.Create('e3'))
  ]);

  Assert.RejectsWith(LPromise, EAggregateException);

  LPromise.InternalWait;
  var LAgg := LPromise.GetFailure.Reason as EAggregateException;
  Assert.AreEqual(3, Length(LAgg.Exceptions));
end;

procedure TTestPromiseAny<T>.AllRejectMessagesPreserved;
var
  LPromise: IPromise<T>;
begin
  LPromise := Promise.Any<T>([
    Promise.Reject<T>(ETestException.Create('alpha')),
    Promise.Reject<T>(ETestException.Create('beta'))
  ]);

  Assert.RejectsWith(LPromise, EAggregateException);

  LPromise.InternalWait;
  var LAgg := LPromise.GetFailure.Reason as EAggregateException;
  Assert.AreEqual(2, Length(LAgg.Exceptions));
  // Check the aggregate message which is built at creation time from inner exception messages
  Assert.IsTrue(LAgg.Message.Contains('alpha'));
  Assert.IsTrue(LAgg.Message.Contains('beta'));
end;

{ TTestPromiseAnyConcurrency }

procedure TTestPromiseAnyConcurrency.StressTestManyPromises;
var
  LPromises: TArray<IPromise<Integer>>;
  LPromise: IPromise<Integer>;
  i: Integer;
const
  COUNT = 50;
begin
  SetLength(LPromises, COUNT);
  // First 49 reject, last one resolves
  for i := 0 to COUNT - 2 do
  begin
    var LIndex := i;
    LPromises[i] := Promise.Reject<Integer>(
      ETestException.Create('error' + IntToStr(LIndex)));
  end;
  LPromises[COUNT - 1] := Promise.Resolve<Integer>(function: Integer
    begin
      Result := 999;
    end);

  LPromise := Promise.Any<Integer>(LPromises);
  Assert.Resolves(LPromise);
  Assert.AreEqual(999, LPromise.Await);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromiseAny<Integer>);
  TDUnitX.RegisterTestFixture(TTestPromiseAny<Boolean>);
  TDUnitX.RegisterTestFixture(TTestPromiseAny<String>);
  TDUnitX.RegisterTestFixture(TTestPromiseAny<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestPromiseAny<TMyObject>);
  TDUnitX.RegisterTestFixture(TTestPromiseAnyConcurrency);

end.
