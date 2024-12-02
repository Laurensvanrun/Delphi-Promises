unit Next.Core.Promises;

interface

uses
  System.Generics.Collections, System.SysUtils, System.SyncObjs, System.Rtti,
  System.Threading, Next.Core.FailureReason, Next.Core.DisposableValue,
  System.Classes;

type
  ENotFullfilledAfterAwait = class(Exception);
  EInternalWaitProblem = class(Exception);

{$REGION 'Interfaces'}
  TPromiseState = (psPending, psFullfilled, psRejected);
  TDisposeValue = (dvFree, dvKeep, dvAssign);

  TConstFunc<T,TResult> = reference to function (const Arg1: T): TResult;
  TConstProc<T> = reference to procedure (const Arg1: T);

{$M+}
  IPromiseSimple = interface
  ['{6293A9C9-795B-4129-B443-DFD86945AFF3}']
    function GetState: TPromiseState;
    procedure InternalWait(ATimeout: Cardinal = INFINITE);

    property State: TPromiseState read GetState;
  end;

  IPromiseAccess = interface(IPromiseSimple)
  ['{8A4401A8-BCD7-47CD-8B28-5F9C62B63F43}']
    function GetPreviousPromiseState: TPromiseState;
    function GetFailure: IFailureReason;
    function GetValueAsTValue: TValue;

{$IFDEF DEBUG}
    function GetPromiseNo: Integer;
    function GetPreviousPromiseNo: Integer;
    procedure SetPromiseNo(Value: Integer);
    procedure SetPreviousPromiseNo(Value: Integer);
{$ENDIF}

    procedure Execute;

    property PreviousPromiseState: TPromiseState read GetPreviousPromiseState;
{$IFDEF DEBUG}
    property PromiseNo: Integer read GetPromiseNo write SetPromiseNo;
    property PreviousPromiseNo: Integer read GetPreviousPromiseNo write SetPreviousPromiseNo;
{$ENDIF}
  end;

  IPromise<T> = interface;

  TPromiseOp<T> = record
  private
    FPromise: IPromise<T>;
  public
    class function Create(APromise: IPromise<T>): TPromiseOp<T>; static;

    function ThenBy<T2>(AFunc: TConstFunc<T, T2>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T2>; overload;
    function ThenBy<T2>(AFunc: TConstFunc<T, IPromise<T2>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T2>; overload;
  end;

  TPromiseMain<T> = record
  private
    FPromise: IPromise<T>;

    class function InternalThenBy<U>(AFunc: TConstFunc<T, U>; AValue: T): U; static;
    class function InternalCatch<U>(AFunc: TFunc<Exception, U>; E: Exception): U; static;
  public
    class function Create(APromise: IPromise<T>): TPromiseMain<T>; static;

    function ThenBy<T2>(AFunc: TConstFunc<T, T2>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T2>; overload;
    function ThenBy<T2>(AFunc: TConstFunc<T, IPromise<T2>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T2>; overload;
    function ThenBy(AFunc: TConstFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>; overload;
    function ThenBy(AFunc: TConstFunc<T, IPromise<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>; overload;
    function ThenBy(AProc: TConstProc<T>): IPromise<T>; overload;

    function Catch(AFunc: TFunc<Exception, T>): IPromise<T>; overload;
    function Catch(AFunc: TFunc<Exception, IPromise<T>>): IPromise<T>; overload;
    function Catch(AProc: TProc<Exception>): IPromise<T>; overload;

    function &Finally(AProc: TProc): IPromise<T>;

    function AssignTo(var ADestination: T): IPromiseSimple; overload;
    function AssignTo(AProc: TConstProc<T>): IPromiseSimple; overload;
  end;

  IPromise<T> = interface(IPromiseAccess)
  ['{300D57D7-1A48-47D7-8C98-ADFCE66B9575}']
    function ThenBy(AFunc: TConstFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>; overload;
    function ThenBy(AFunc: TConstFunc<T, IPromise<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>; overload;
    function ThenBy(AProc: TConstProc<T>): IPromise<T>; overload;

    function Op: TPromiseOp<T>;
    function Main: TPromiseMain<T>;

    function Catch(AFunc: TFunc<Exception, T>): IPromise<T>; overload;
    function Catch(AFunc: TFunc<Exception, IPromise<T>>): IPromise<T>; overload;
    function Catch(AProc: TProc<Exception>): IPromise<T>; overload;

    function &Finally(AProc: TProc): IPromise<T>;

    function Await: T;
  end;
{$ENDREGION}

{$REGION 'Implementation'}
  TAbstractPromise<T> = class(TInterfacedObject, IPromise<T>, IPromiseAccess)
  private
    FState: TPromiseState;
    FValue: TDisposableValue<T>;
    FFailure: IFailureReason;
    FSignal: TEvent;
{$IFDEF DEBUG}
    FPromiseNo: Integer;
    FPreviousPromiseNo: Integer;
{$ENDIF}
    function GetState: TPromiseState;

    procedure SetValue(AValue: TDisposableValue<T>);
    function GetValueAsTValue: TValue;

    procedure SetFailure(AFailure: IFailureReason);
    function GetFailure: IFailureReason;

    procedure InternalWait(ATimeout: Cardinal = INFINITE);

{$IFDEF DEBUG}
    function GetPromiseNo: Integer;
    function GetPreviousPromiseNo: Integer;
    procedure SetPromiseNo(Value: Integer);
    procedure SetPreviousPromiseNo(Value: Integer);
{$ENDIF}
  protected
    procedure Resolve(AValue: TDisposableValue<T>);
    procedure Reject(AFailure: IFailureReason);

    procedure Execute; virtual; abstract;
    function GetPreviousPromiseState: TPromiseState; virtual; abstract;

    procedure InternalExecute(AResolveFunc: TFunc<TDisposableValue<T>>);
  public
    constructor Create;
    destructor Destroy; override;

    function ThenBy(AFunc: TConstFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>; overload;
    function ThenBy(AFunc: TConstFunc<T, IPromise<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>; overload;
    function ThenBy(AProc: TConstProc<T>): IPromise<T>; overload;

    function Op: TPromiseOp<T>;
    function Main: TPromiseMain<T>;

    function Catch(AFunc: TFunc<Exception, T>): IPromise<T>; overload;
    function Catch(AFunc: TFunc<Exception, IPromise<T>>): IPromise<T>; overload;
    function Catch(AProc: TProc<Exception>): IPromise<T>; overload;

    function &Finally(AProc: TProc): IPromise<T>;

    function Await: T;

    property State: TPromiseState read GetState;
  end;

  //Special case: first promise in a row just returns the value of the anonymous
  TFirstPromise<T> = class(TAbstractPromise<T>)
    FFunc: TFunc<T>;

    procedure Execute; override;
    function GetPreviousPromiseState: TPromiseState; override;
  public
    constructor Create(AFunc: TFunc<T>); reintroduce;
  end;

  TPromise<T, T2> = class(TAbstractPromise<T2>)
  private
    FFunc: TConstFunc<T, T2>;
    FCatchFunc: TFunc<Exception, T2>;
    FDispose: TDisposeValue;

    FPreviousPromise: IPromise<T>;
  protected
    procedure Execute; override;
    function GetPreviousPromiseState: TPromiseState; override;
  public
    constructor Create(AFunc: TConstFunc<T, T2>; ACatchFunc: TFunc<Exception, T2>; APreviousPromise: IPromise<T>; ADispose: TDisposeValue); reintroduce;
  end;

  //Special case: if the previous promise returns a promise we have to wait
  //until that promise is resolved. When we execute the "extraction" (see
  //TPromiseInPromise) we have to compare the result value to the input value
  //for the memory management. Therefore we need a special type that saves a
  //copy of the input type for comparison.
  IPromiseKeepInputValue<T> = interface(IPromise<IPromiseAccess>)
    function GetInputValue: T;
  end;

  TPromiseKeepInputValue<T> = class(TPromise<T, IPromiseAccess>, IPromiseKeepInputValue<T>)
  private
    FPreviousValue: T;

    procedure SetInputValue(AValue: T);
    function GetInputValue: T;
  protected
    procedure Execute; override;
  public
    constructor Create(AFunc: TConstFunc<T, IPromiseAccess>; ACatchFunc: TFunc<Exception, IPromiseAccess>; APreviousPromise: IPromise<T>); reintroduce;
  end;

  //Special case: if the previous promise returns a promise we have to wait
  //until that promise is resolved. Another option would be to Await in the
  //anonymous caller, but that could cause deadlocks.
  TPromiseInPromise<T, T2> = class(TAbstractPromise<T2>)
  private
    FDispose: TDisposeValue;
    FPreviousPromise: IPromiseKeepInputValue<T>;
  protected
    procedure Execute; override;
    function GetPreviousPromiseState: TPromiseState; override;
  public
    constructor Create(APreviousPromise: IPromiseKeepInputValue<T>; ADispose: TDisposeValue); reintroduce;
  end;
{$ENDREGION}

{$REGION 'Promise scheduler'}
  IPromiseSchedulerExceptionLogger = interface
  ['{B72EFE92-DE48-480E-844E-8A29B97CC7F6}']
    procedure FatalPromiseException(APromiseClassname: String; AException: Exception);
  end;

  IPromiseScheduler = interface
  ['{E12C1A8A-F196-4FA8-BA5C-10551454C50F}']
    function SignalToken: TSemaphore;
    function GiveNextPromise: IPromiseAccess;

    procedure IncreaseIdleThread;
    procedure DecreaseIdleThread;

    procedure Start;
    procedure Schedule(APromise: IPromiseAccess);
    procedure Signal;

    procedure LogFatalException(APromiseClassname: String; AException: Exception);
    procedure SetLogger(ALogger: IPromiseSchedulerExceptionLogger);
  end;

  TPromiseScheduler = class(TInterfacedObject, IPromiseScheduler)
  public const
    MAX_POOL_SIZE = 50;
    MIN_POOL_SIZE = 10;
  protected type
    TPromiseThread = class(TThread)
    private
      FCancel: TEvent;
      [unsafe] FScheduler: IPromiseScheduler;
    public
      constructor Create([unsafe] AScheduler: IPromiseScheduler);
      destructor Destroy; override;
      procedure Execute; override;
      procedure Cancel;
    end;
  private
    FController: ITask;
    FSignalController: TEvent;
    FSignalControllerRevision: Int64;
    FCancel: TEvent;

    FSignal: TSemaphore;
    FThreads: TList<TPromiseThread>;
    FIdleThreads: Integer;

    FExceptionLogger: IPromiseSchedulerExceptionLogger;
    FThreadPoolIsMaxSize: Boolean;

    procedure AddThread;

    function GrowPool: Boolean;
    procedure ControlPool;

    procedure SetLogger(ALogger: IPromiseSchedulerExceptionLogger);
    procedure LogFatalException(APromiseClassname: String; AException: Exception);
    procedure SignalControllerIf;
  protected
    FPromises: TList<IPromiseAccess>;

    function SignalToken: TSemaphore;
    function GiveNextPromise: IPromiseAccess;

    procedure IncreaseIdleThread;
    procedure DecreaseIdleThread;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    procedure Schedule(APromise: IPromiseAccess);
    procedure Signal;
  end;
{$ENDREGION}

  Promise = class
  private
    class function Rejector<T>(APromise: IPromise<T>): TProc<Exception>;
    class function Resolver<T>(APromise: IPromise<T>): TProc<T>; static;
  public
    class function New<T>(AProc: TProc<TProc<T>, TProc<Exception>>): IPromise<T>;
    class function All(const AArray: TArray<IPromiseAccess>): IPromise<TArray<TValue>>; overload;
    class function All<T>(const AArray: TArray<IPromise<T>>): IPromise<TArray<T>>; overload;
    class function Resolve<T>(AFunc: TFunc<T>): IPromise<T>; overload;
    class function Reject<T>(E: Exception): IPromise<T>;
  end;

  procedure CreatePromiseSchedulerIf;

var
  _Scheduler: IPromiseScheduler;

implementation

uses
  Winapi.Windows, System.TypInfo;

{ TPromise<T> }

{CreatePromiseSchedulerIf called from two places,
 1. Initialization from this unit
 2. constructor THelperDestroyFactory.Create

 _Scheduler object set to nil in destructor THelperDestroyFactory.Destroy;
}

procedure CreatePromiseSchedulerIf;
begin
   if not Assigned(_Scheduler) then begin
    _Scheduler := TPromiseScheduler.Create;
    _Scheduler.Start;
   end;
end;

function TAbstractPromise<T>.&Finally(AProc: TProc): IPromise<T>;
begin
  Result := Self
    .ThenBy(procedure(const v: T) begin AProc(); end)
    .Catch(procedure(E: Exception) begin AProc(); end);
end;

function TAbstractPromise<T>.Await: T;
var
  LException: Exception;
begin
  InternalWait;

  System.TMonitor.Enter(Self);
  try
    if State = psRejected then begin
      LException := GetFailure.Reason;
      raise GetFailure.DetachExceptionObject;
    end else if State = psFullfilled then begin
      Result := FValue;
      FValue.&Nil;
    end else
      raise ENotFullfilledAfterAwait.Create('InternalAwait finished, but our state is: ' + GetEnumName(TypeInfo(TPromiseState), Ord(State)));
  finally
    System.TMonitor.Exit(Self);
  end;
end;

function TAbstractPromise<T>.Catch(AFunc: TFunc<Exception, T>): IPromise<T>;
begin
  Result := TPromise<T, T>.Create(function(const AIn: T): T begin
    Result := AIn end
    , AFunc, Self, TDisposeValue.dvFree);
  _Scheduler.Schedule(Result);
end;

function TAbstractPromise<T>.Catch(AFunc: TFunc<Exception, IPromise<T>>): IPromise<T>;
var
  LFirst: IPromiseKeepInputValue<T>;
begin
  LFirst := TPromiseKeepInputValue<T>.Create(function(const A: T): IPromiseAccess
    begin
      Result := Promise.Resolve<T>(function: T
        begin
          Result := A
        end);
    end,
    function(E: Exception): IPromiseAccess
      begin
        Result := AFunc(E);
      end,
    Self);
  _Scheduler.Schedule(LFirst);

  Result := TPromiseInPromise<T, T>.Create(LFirst, TDisposeValue.dvFree);
  _Scheduler.Schedule(Result);
end;

function TAbstractPromise<T>.Catch(AProc: TProc<Exception>): IPromise<T>;
begin
  Result := Catch(function(E: Exception): T begin AProc(E); raise E; end);
end;

constructor TAbstractPromise<T>.Create;
begin
  inherited;

  FState := psPending;
  FSignal := TEvent.Create;
end;

destructor TAbstractPromise<T>.Destroy;
begin
  FreeAndNil(FSignal);
  FValue.Dispose;

  inherited;
end;

function TAbstractPromise<T>.GetFailure: IFailureReason;
begin
  System.TMonitor.Enter(Self);
  try
    Result := FFailure;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

{$IFDEF DEBUG}
function TAbstractPromise<T>.GetPreviousPromiseNo: Integer;
begin
  System.TMonitor.Enter(Self);
  try
    Result := FPreviousPromiseNo;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

function TAbstractPromise<T>.GetPromiseNo: Integer;
begin
  System.TMonitor.Enter(Self);
  try
    Result := FPromiseNo;
  finally
    System.TMonitor.Exit(Self);
  end;
end;
{$ENDIF}

function TAbstractPromise<T>.GetState: TPromiseState;
begin
  System.TMonitor.Enter(Self);
  try
    Result := FState;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

function TAbstractPromise<T>.GetValueAsTValue: TValue;
begin
  Result := TValue.From<T>(Await);
end;

procedure TAbstractPromise<T>.InternalExecute(AResolveFunc: TFunc<TDisposableValue<T>>);
begin
  try
    Resolve(AResolveFunc);
  except
    Reject(TFailureReason.Create(AcquireExceptionObject));
  end;
end;

procedure TAbstractPromise<T>.InternalWait(ATimeout: Cardinal);
const
  MT_SIGNAL_WAIT = 10;
  MT_SYNC_WAIT = 10;
var
  LRunning: Cardinal;
begin
  if State = psPending then begin
    if TThread.CurrentThread.ThreadID = MainThreadID then begin
      LRunning := 0;
      while (not (FSignal.WaitFor(MT_SIGNAL_WAIT) = wrSignaled)) and (LRunning < ATimeout) do begin
        CheckSynchronize(MT_SYNC_WAIT);
        LRunning := LRunning + MT_SIGNAL_WAIT + MT_SYNC_WAIT;
      end;
    end else begin
      var LResult := FSignal.WaitFor(ATimeout);
      if LResult <> TWaitResult.wrSignaled then
        raise EInternalWaitProblem.Create('Issue waiting for signal (not set before timeout?): ' + GetEnumName(TypeInfo(TWaitResult), Ord(LResult)));
    end;
  end;
end;

function TAbstractPromise<T>.Main: TPromiseMain<T>;
begin
  Result := TPromiseMain<T>.Create(Self);
end;

function TAbstractPromise<T>.Op: TPromiseOp<T>;
begin
  Result := TPromiseOp<T>.Create(Self);
end;

procedure TAbstractPromise<T>.Reject(AFailure: IFailureReason);
begin
  SetFailure(AFailure);

  System.TMonitor.Enter(Self);
  try
    FState := psRejected;
  finally
    System.TMonitor.Exit(Self);
  end;
  //Signal Await that we are done
  FSignal.SetEvent;

  //Signal scheduler that we are done, but only if the scheduler is not being destroyed
  if Assigned(_Scheduler) then
    _Scheduler.Signal;
end;

procedure TAbstractPromise<T>.Resolve(AValue: TDisposableValue<T>);
begin
  SetValue(AValue);

  System.TMonitor.Enter(Self);
  try
    FState := psFullfilled;
  finally
    System.TMonitor.Exit(Self);
  end;
  //Signal Await that we are done
  FSignal.SetEvent;

  //Signal scheduler that we are done, but only if the scheduler is not being destroyed
  if Assigned(_Scheduler) then
    _Scheduler.Signal;
end;

procedure TAbstractPromise<T>.SetFailure(AFailure: IFailureReason);
begin
  System.TMonitor.Enter(Self);
  try
    FFailure := AFailure;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

{$IFDEF DEBUG}
procedure TAbstractPromise<T>.SetPreviousPromiseNo(Value: Integer);
begin
  System.TMonitor.Enter(Self);
  try
    FPreviousPromiseNo := Value;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

procedure TAbstractPromise<T>.SetPromiseNo(Value: Integer);
begin
  System.TMonitor.Enter(Self);
  try
    FPromiseNo := Value;
  finally
    System.TMonitor.Exit(Self);
  end;
end;
{$ENDIF}

procedure TAbstractPromise<T>.SetValue(AValue: TDisposableValue<T>);
begin
  System.TMonitor.Enter(Self);
  try
    FValue := AValue;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

function TAbstractPromise<T>.ThenBy(AProc: TConstProc<T>): IPromise<T>;
begin
  Result := ThenBy(function(const I: T): T begin AProc(I); Result := I; end);
end;

function TAbstractPromise<T>.ThenBy(AFunc: TConstFunc<T, IPromise<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>;
var
  LFirst: IPromiseKeepInputValue<T>;
begin
  LFirst := TPromiseKeepInputValue<T>.Create(function(const A: T): IPromiseAccess
    begin
      Result := AFunc(A);
    end,
    nil, Self);
  _Scheduler.Schedule(LFirst);

  Result := TPromiseInPromise<T, T>.Create(LFirst, ADispose);
  _Scheduler.Schedule(Result);
end;

function TAbstractPromise<T>.ThenBy(AFunc: TConstFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T>;
begin
  Result := TPromise<T, T>.Create(AFunc, nil, Self, ADispose);
  _Scheduler.Schedule(Result);
end;

{ TPromiseOp<T> }

class function TPromiseOp<T>.Create(
  APromise: IPromise<T>): TPromiseOp<T>;
begin
  Assert(Assigned(APromise));

  Result.FPromise := APromise;
end;

function TPromiseOp<T>.ThenBy<T2>(AFunc: TConstFunc<T, T2>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T2>;
begin
  Result := TPromise<T,T2>.Create(function(const AArgument: T): T2 begin
    Result := AFunc(AArgument);
  end, nil, FPromise, ADispose);
  _Scheduler.Schedule(Result);
end;

function TPromiseOp<T>.ThenBy<T2>(AFunc: TConstFunc<T, IPromise<T2>>; ADispose: TDisposeValue = TDisposeValue.dvFree): IPromise<T2>;
var
  LFirst: IPromiseKeepInputValue<T>;
begin
  LFirst := TPromiseKeepInputValue<T>.Create(function(const A: T): IPromiseAccess
    begin
      Result := AFunc(A);
    end,
    nil, FPromise);
  _Scheduler.Schedule(LFirst);

  Result := TPromiseInPromise<T, T2>.Create(LFirst, ADispose);
  _Scheduler.Schedule(Result);
end;

{ Promise }

class function Promise.Resolve<T>(AFunc: TFunc<T>): IPromise<T>;
begin
  Result := TFirstPromise<T>.Create(AFunc);
  _Scheduler.Schedule(Result);
end;

class function Promise.All(const AArray: TArray<IPromiseAccess>): IPromise<TArray<TValue>>;
begin
  Result := TFirstPromise<TArray<TValue>>.Create(function: TArray<TValue>
    var
      i, j: Integer;
    begin
      SetLength(Result, Length(AArray));
      i := Low(AArray);
      try
        for i := Low(AArray) to High(AArray) do begin
          Assert(Assigned(AArray[i]));
          AArray[i].InternalWait;
          Result[i] := AArray[i].GetValueAsTValue;
        end;
        i := High(AArray);
      except
        //On exception, dispose all objects in array to prevent leaks
        for j := Low(AArray) to i do
          if Result[j].Kind = tkClass then
            Result[j].AsObject.Free;

        raise;
      end;
    end);
  _Scheduler.Schedule(Result);
end;

class function Promise.All<T>(
  const AArray: TArray<IPromise<T>>): IPromise<TArray<T>>;
var
  LArray: TArray<IPromiseAccess>;
  i: Integer;
begin
  SetLength(LArray, Length(AArray));
  for i := Low(AArray) to High(AArray) do
    LArray[i] := AArray[i];

  Result := Promise.All(LArray)
    .Op.ThenBy<TArray<T>>(function(const AArray: TArray<TValue>): TArray<T>
      var
        i: Integer;
      begin
        SetLength(Result, Length(AArray));
        for i := Low(AArray) to High(AArray) do
          Result[i] := AArray[i].AsType<T>;
      end, dvKeep);
end;

class function Promise.Resolver<T>(APromise: IPromise<T>): TProc<T>;
begin
  Result := procedure(AValue: T)
    begin
      TFirstPromise<T>(APromise).Resolve(AValue);
    end;
end;

class function Promise.Rejector<T>(APromise: IPromise<T>): TProc<Exception>;
begin
  Result := procedure(E: Exception)
    begin
      TFirstPromise<T>(APromise).Reject(TFailureReason.Create(E));
    end;
end;

class function Promise.New<T>(
  AProc: TProc<TProc<T>, TProc<Exception>>): IPromise<T>;
begin
  Result := TFirstPromise<T>.Create(function: T begin
    Result := Default(T);
  end);

  //We use seperate methods to create the resolver and rejector to trick the
  //compiler in increasing the reference count of our resulting promise. Only
  //when all references to all anonymous methods (so, including the references
  //to these resolve and reject methods) are gone, then the reference count of
  //the promise will be decreased again.
  //
  //This way we make sure that we can safely call the resolve or reject methods,
  //even if the original result (promise) gets out-of-scope in the caller of this
  //method.

  AProc(Resolver<T>(Result), Rejector<T>(Result));
end;

class function Promise.Reject<T>(E: Exception): IPromise<T>;
begin
  Result := TFirstPromise<T>.Create(function: T begin raise E end);
  _Scheduler.Schedule(Result);
end;

{ TPromise<T, T2> }

constructor TPromise<T, T2>.Create(AFunc: TConstFunc<T, T2>;
  ACatchFunc: TFunc<Exception, T2>; APreviousPromise: IPromise<T>;
  ADispose: TDisposeValue);
begin
  Assert(Assigned(AFunc));
  Assert(Assigned(APreviousPromise));

  FFunc := AFunc;
  FCatchFunc := ACatchFunc;
  FPreviousPromise := APreviousPromise;
  FDispose := ADispose;
{$IFDEF DEBUG}
  FPreviousPromiseNo := APreviousPromise.PromiseNo;
{$ENDIF}

  inherited Create;
end;

procedure TPromise<T, T2>.Execute;
begin
  if GetPreviousPromiseState = psRejected then begin
    if Assigned(FCatchFunc) then
      InternalExecute(function: TDisposableValue<T2>
      var
        LE: Exception;
      begin
        LE := FPreviousPromise.GetFailure.Reason;
        try
          Result := FCatchFunc(LE);
        except
          on E: Exception do begin
            //If the same exception is re-raised, we must detach the exception
            //object from the previous promise. This raise makes that the
            //exception object is inserted in our IFailureReason-object (which
            //will be destroyed if this promise is destroyed). However, the
            //previous promise also holds a reference to this object and if we
            //do not detach it here, it will be destroyed as the previous
            //promise is destroyed (and then we have a dangling pointer in our
            //IFailureReason-object).
            if E = LE then
              FPreviousPromise.GetFailure.DetachExceptionObject;

            raise;
          end;
        end;
      end)
    else
      Reject(FPreviousPromise.GetFailure)
  end else begin
    InternalExecute(function: TDisposableValue<T2>
      var
        LValue: TDisposableValue<T>;
        LResult: T2;
      begin
        try
          LValue := FPreviousPromise.Await;
          try
            LResult := FFunc(LValue);
            Result := LResult;
          finally
            case FDispose of
              dvFree: LValue.TryDispose<T2>(LResult);
              dvAssign: Result.&Nil;
              dvKeep: LValue.&Nil;
            end;
          end;
        except
          on E: EDisposableValueException do begin
            E.Message := E.Message + ' (PreviousPromise state: ' + GetEnumName(TypeInfo(TPromiseState), Ord(FPreviousPromise.State)) + ')';

            raise;
          end;
        end;
      end)
  end;

  //We explicit remove the references to FFunc and FCatchFunc here to prevent reference cycles
  //with anonymous methods and closures, see https://stackoverflow.com/questions/51213638/why-is-this-interface-not-correctly-released-when-the-method-is-exited/51221496#51221496
  //and https://quality.embarcadero.com/browse/RSP-30430
  FCatchFunc := nil;
  FFunc := nil;
end;

function TPromise<T, T2>.GetPreviousPromiseState: TPromiseState;
begin
  Result := FPreviousPromise.State;
end;

{ TFirstPromise<T> }

constructor TFirstPromise<T>.Create(AFunc: TFunc<T>);
begin
  Assert(Assigned(AFunc));
  FFunc := AFunc;

  inherited Create;
end;

procedure TFirstPromise<T>.Execute;
begin
  InternalExecute(function: TDisposableValue<T> begin Result := FFunc end);

  //We explicit remove the reference to FFunc here to prevent reference cycles
  //with anonymous methods and closures, see https://stackoverflow.com/questions/51213638/why-is-this-interface-not-correctly-released-when-the-method-is-exited/51221496#51221496
  //and https://quality.embarcadero.com/browse/RSP-30430
  FFunc := nil;
end;

function TFirstPromise<T>.GetPreviousPromiseState: TPromiseState;
begin
  Result := psFullfilled;
end;

{ TPromiseInPromise<T> }

constructor TPromiseInPromise<T, T2>.Create(APreviousPromise: IPromiseKeepInputValue<T>; ADispose: TDisposeValue);
begin
  Assert(Assigned(APreviousPromise));
  FPreviousPromise := APreviousPromise;
  FDispose := ADispose;

  inherited Create;
end;

procedure TPromiseInPromise<T, T2>.Execute;
begin
  InternalExecute(function: TDisposableValue<T2>
    var
      LValue: TDisposableValue<T>;
      LResult: T2;
    begin
      try
        LValue := FPreviousPromise.GetInputValue;
        try
          LResult := FPreviousPromise.Await.GetValueAsTValue.AsType<T2>;
          Result := LResult;
        finally
          case FDispose of
            dvFree: LValue.TryDispose<T2>(LResult);
            dvAssign: Result.&Nil;
            dvKeep: LValue.&Nil;
          end;
        end;
      except
        on E: EDisposableValueException do begin
          E.Message := E.Message + ' (PreviousPromise state: ' + GetEnumName(TypeInfo(TPromiseState), Ord(FPreviousPromise.State)) + ')';

          raise;
        end;
      end
    end);
end;

function TPromiseInPromise<T, T2>.GetPreviousPromiseState: TPromiseState;
begin
  Result := FPreviousPromise.State;
  if FPreviousPromise.State = psFullfilled then
    Result := FPreviousPromise.Await.State;
end;

{ TPromiseScheduler }

procedure TPromiseScheduler.Schedule(APromise: IPromiseAccess);
begin
  System.TMonitor.Enter(FPromises);
  try
    FPromises.Add(APromise);
  finally
    System.TMonitor.Exit(FPromises);
  end;
  Signal();
  SignalControllerIf();
end;

procedure TPromiseScheduler.SetLogger(ALogger: IPromiseSchedulerExceptionLogger);
begin
  System.TMonitor.Enter(Self);
  try
    FExceptionLogger := ALogger;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

procedure TPromiseScheduler.AddThread;
begin
  FThreads.Add(TPromiseThread.Create(Self));
  FThreads.Last.NameThreadForDebugging('Promise worker - #' + FThreads.Count.ToString(), FThreads.Last.ThreadID);
  FThreadPoolIsMaxSize := (FThreads.Count >= MAX_POOL_SIZE);
end;

procedure TPromiseScheduler.ControlPool;
var LEvents: Array[0..1] of THandle;
begin
  LEvents[0] := FCancel.Handle;
  LEvents[1] := FSignalController.Handle;
  var LCancel := False;

  for var i := 0 to MIN_POOL_SIZE - 1 do
    AddThread();

  while (not LCancel) do begin
    const LWaitResult = WaitForMultipleObjectsEx(2, @LEvents, False, INFINITE, False);
    case LWaitResult of
      WAIT_OBJECT_0: LCancel := True;

      WAIT_OBJECT_0 + 1: begin
        FSignalController.ResetEvent;
        const LRevisionBefore = TInterlocked.Read(FSignalControllerRevision);

        if GrowPool() then begin
          //Take it easy, only grow/shrink every 100ms
          if FCancel.WaitFor(100) = wrSignaled then
            LCancel := True;
        end;

        const LRevisionAfter = TInterlocked.Read(FSignalControllerRevision);
        if LRevisionBefore <> LRevisionAfter then
          SignalControllerIf();
      end;
    end;
  end;

  for var LThread in FThreads do begin
    LThread.Cancel;
    LThread.WaitFor;
    LThread.Free;
  end;
end;

constructor TPromiseScheduler.Create;
begin
  FPromises := TList<IPromiseAccess>.Create;
  FThreads := TList<TPromiseThread>.Create;

  FSignal := TSemaphore.Create(nil, 0, 9999, '');

  FSignalController := TEvent.Create;
  FSignalControllerRevision := 0;

  FCancel := TEvent.Create();
  FIdleThreads := 0;

  FController := TTask.Create(ControlPool);
end;

procedure TPromiseScheduler.DecreaseIdleThread;
begin
  AtomicDecrement(FIdleThreads);
end;

destructor TPromiseScheduler.Destroy;
begin
  FCancel.SetEvent;
  if (FController.Status = TTaskStatus.Running) or
    (FController.Status = TTaskStatus.WaitingToRun) then
    FController.Wait;

  FreeAndNil(FSignalController);
  FreeAndNil(FThreads);
  FreeAndNil(FPromises);
  FreeAndNil(FCancel);
  FreeAndNil(FSignal);

  inherited;
end;

function TPromiseScheduler.GiveNextPromise: IPromiseAccess;
var
  i:  Integer;
  LPromise: IPromiseAccess;
begin
  Result := nil;
  System.TMonitor.Enter(FPromises);
  try
    for i := 0 to FPromises.Count - 1 do begin
      LPromise := FPromises[i];

      if LPromise.PreviousPromiseState <> psPending then begin
        FPromises.Extract(LPromise);
        Result := LPromise;
        Exit;
      end;
    end;
  finally
    System.TMonitor.Exit(FPromises);
  end;
end;

function TPromiseScheduler.GrowPool: Boolean;
var
  LPromiseCount: Integer;
begin
  Result := False;

  System.TMonitor.Enter(FPromises);
  try
    LPromiseCount := FPromises.Count;
  finally
    System.TMonitor.Exit(FPromises);
  end;

  //Increase size
  if (LPromiseCount > FIdleThreads) then begin
    if (FThreads.Count < MAX_POOL_SIZE) then begin
      AddThread();

      //could be that GrowPool was triggered by multiple promises, so we might need to grow more
      SignalControllerIf();
      Result := True;
    end
    //else: nothing to do, pool is already at max size, and shrinking the pool isn't supported yet
  end;
end;

procedure TPromiseScheduler.IncreaseIdleThread;
begin
  AtomicIncrement(FIdleThreads);
end;

procedure TPromiseScheduler.LogFatalException(APromiseClassname: String;
  AException: Exception);
begin
  System.TMonitor.Enter(Self);
  try
    if Assigned(FExceptionLogger) then
      FExceptionLogger.FatalPromiseException(APromiseClassname, AException);
  finally
    System.TMonitor.Exit(Self);
  end;
end;

procedure TPromiseScheduler.Signal;
begin
  FSignal.Release;
end;

procedure TPromiseScheduler.SignalControllerIf;
begin
  if not FThreadPoolIsMaxSize then begin
    TInterlocked.Increment(FSignalControllerRevision); //will rollover to MinInt when the max is reached
    FSignalController.SetEvent;
  end;
end;

function TPromiseScheduler.SignalToken: TSemaphore;
begin
  Result := FSignal;
end;

procedure TPromiseScheduler.Start;
begin
  FController.Start;
end;

{ TPromiseMain<T> }

function TPromiseMain<T>.Catch(AFunc: TFunc<Exception, IPromise<T>>): IPromise<T>;
var
  LFirst: IPromiseKeepInputValue<T>;
begin
  LFirst := TPromiseKeepInputValue<T>.Create(function(const A: T): IPromiseAccess
    begin
      Result := Promise.Resolve<T>(function: T
        begin
          Result := A
        end);
    end,
    function(E: Exception): IPromiseAccess
      begin
        Result := InternalCatch<IPromise<T>>(AFunc, E);
      end,
    FPromise);
  _Scheduler.Schedule(LFirst);

  Result := TPromiseInPromise<T, T>.Create(LFirst, TDisposeValue.dvFree);
  _Scheduler.Schedule(Result);
end;

function TPromiseMain<T>.Catch(AFunc: TFunc<Exception, T>): IPromise<T>;
begin
  Result := TPromise<T, T>.Create(
    function(const AIn: T): T
    begin
      Result := AIn
    end,

    function(E: Exception): T
    begin
      Result := InternalCatch<T>(AFunc, E);
    end, FPromise, TDisposeValue.dvFree);
  _Scheduler.Schedule(Result);
end;

function TPromiseMain<T>.AssignTo(var ADestination: T): IPromiseSimple;
var
  APointer: Pointer;
begin
  APointer := @ADestination;
  Result := ThenBy<T>(function(const A: T): T begin
    T(APointer^) := A;
    Result := A;
  end, TDisposeValue.dvAssign);
end;

function TPromiseMain<T>.&Finally(AProc: TProc): IPromise<T>;
begin
  Result := Self
    .ThenBy(procedure(const v: T) begin AProc(); end)
    .Main.Catch(procedure(E: Exception) begin AProc(); end);
end;

function TPromiseMain<T>.AssignTo(AProc: TConstProc<T>): IPromiseSimple;
begin
  Result := ThenBy<T>(function(const A: T): T begin
    AProc(A);
    Result := A;
  end, TDisposeValue.dvAssign);
end;

function TPromiseMain<T>.Catch(AProc: TProc<Exception>): IPromise<T>;
begin
  Result := Catch(function(E: Exception): T begin AProc(E); raise E; end);
end;

class function TPromiseMain<T>.Create(
  APromise: IPromise<T>): TPromiseMain<T>;
begin
  Assert(Assigned(APromise));

  Result.FPromise := APromise;
end;

class function TPromiseMain<T>.InternalThenBy<U>(AFunc: TConstFunc<T, U>; AValue: T): U;
var
  LResult: U;
  LSignal: TEvent;
  LException: TObject;
begin
  LSignal := TEvent.Create;
  try
    LException := nil;

    TThread.ForceQueue(nil, procedure begin
      try
        try
          LResult := AFunc(AValue);
        except
          LException := AcquireExceptionObject;
        end;
      finally
        LSignal.SetEvent;
      end;
    end);

    if TThread.CurrentThread.ThreadID = MainThreadID then
      while not (LSignal.WaitFor(10) = wrSignaled) do
        CheckSynchronize(10)
    else
      LSignal.WaitFor;

    if Assigned(LException) then
      raise LException;
  finally
    FreeAndNil(LSignal);
  end;

  Result := LResult;
end;

class function TPromiseMain<T>.InternalCatch<U>(AFunc: TFunc<Exception, U>;
  E: Exception): U;
var
  LResult: U;
  LSignal: TEvent;
  LException: TObject;
begin
  LSignal := TEvent.Create;
  try
    LException := nil;

    TThread.ForceQueue(nil, procedure begin
      try
        try
          LResult := AFunc(E);
        except
          LException := AcquireExceptionObject;
        end;
      finally
        LSignal.SetEvent;
      end;
    end);

    if TThread.CurrentThread.ThreadID = MainThreadID then
      while not (LSignal.WaitFor(10) = wrSignaled) do
        CheckSynchronize(10)
    else
      LSignal.WaitFor;

    if Assigned(LException) then
      raise LException;
  finally
    FreeAndNil(LSignal);
  end;

  Result := LResult;
end;

function TPromiseMain<T>.ThenBy<T2>(AFunc: TConstFunc<T, T2>;
  ADispose: TDisposeValue): IPromise<T2>;
begin
  Result := TPromise<T, T2>.Create(function(const A: T): T2 begin
    Result := InternalThenBy<T2>(AFunc, A);
  end, nil, FPromise, ADispose);
  _Scheduler.Schedule(Result);
end;

function TPromiseMain<T>.ThenBy(AProc: TConstProc<T>): IPromise<T>;
begin
  Result := ThenBy<T>(function(const I: T): T begin AProc(I); Result := I; end);
end;

function TPromiseMain<T>.ThenBy(AFunc: TConstFunc<T, IPromise<T>>;
  ADispose: TDisposeValue): IPromise<T>;
begin
  Result := ThenBy<T>(AFunc, ADispose);
end;

function TPromiseMain<T>.ThenBy(AFunc: TConstFunc<T, T>;
  ADispose: TDisposeValue): IPromise<T>;
begin
  Result := ThenBy<T>(AFunc, ADispose);
end;

function TPromiseMain<T>.ThenBy<T2>(AFunc: TConstFunc<T, IPromise<T2>>;
  ADispose: TDisposeValue): IPromise<T2>;
var
  LFirst: IPromiseKeepInputValue<T>;
begin
  LFirst := TPromiseKeepInputValue<T>.Create(function(const A: T): IPromiseAccess
    begin
      Result := InternalThenBy<IPromise<T2>>(AFunc, A);
    end,
    nil, FPromise);
  _Scheduler.Schedule(LFirst);

  Result := TPromiseInPromise<T, T2>.Create(LFirst, ADispose);
  _Scheduler.Schedule(Result);
end;

{ TPromiseScheduler.TPromiseThread }

procedure TPromiseScheduler.TPromiseThread.Cancel;
begin
  FCancel.SetEvent;
end;

constructor TPromiseScheduler.TPromiseThread.Create(
  [unsafe] AScheduler: IPromiseScheduler);
begin
  inherited Create;

  FCancel := TEvent.Create();
  FScheduler := AScheduler;
end;

destructor TPromiseScheduler.TPromiseThread.Destroy;
begin
  FreeAndNil(FCancel);

  inherited;
end;

procedure TPromiseScheduler.TPromiseThread.Execute;
var
  LEvents: Array[0..1] of THandle;
  LWaitResult: Cardinal;
  LCancel: Boolean;
  LPromise: IPromiseAccess;
  LPromiseClassname: String;
begin
  inherited;

  LEvents[0] := FCancel.Handle;
  LEvents[1] := FScheduler.SignalToken.Handle;
  LCancel := False;

  while (not LCancel) do begin
    try
      FScheduler.IncreaseIdleThread;
      try
        LWaitResult := WaitForMultipleObjectsEx(2, @LEvents, False, INFINITE, False);
      finally
        FScheduler.DecreaseIdleThread;
      end;

      if LWaitResult = WAIT_OBJECT_0 then
        LCancel := True;
      if LWaitResult = WAIT_OBJECT_0 + 1 then begin
        LPromise := FScheduler.GiveNextPromise;
        if Assigned(LPromise) then begin
          LPromiseClassname := (LPromise as TObject).ClassName;
          LPromise.Execute;
          //Remove reference to promise here to make sure that the underlying
          //value in the promise is destroyed as soon as possible. Otherwise
          //there still is a reference to the promise in this thread, which can
          //exists until the very end of the program. If the underlying value
          //is an object (or interface to a non-ref.counted object) the object
          //will already be destroyed before this thread is destroyed, which will
          //cause an access violation (because _Release is always called on an
          //interfaced type).
          LPromise := nil;
        end;
      end;
    except
      on E: Exception do
        FScheduler.LogFatalException(LPromiseClassName, E);
    end;
  end;
end;

{ TPromiseKeepInputValue<T> }

constructor TPromiseKeepInputValue<T>.Create(AFunc: TConstFunc<T, IPromiseAccess>;
  ACatchFunc: TFunc<Exception, IPromiseAccess>;
  APreviousPromise: IPromise<T>);
begin
  //DisposeValue is not used here in .Execute
  inherited Create(AFunc, ACatchFunc, APreviousPromise, TDisposeValue.dvKeep);
end;

procedure TPromiseKeepInputValue<T>.Execute;
begin
  if GetPreviousPromiseState = psRejected then
    inherited
  else begin
    InternalExecute(function: TDisposableValue<IPromiseAccess>
      begin
        //In the .Execute of TPromiseInPromise<T> we compare the "extracted"
        //promise value (result of FFunc(...) which returns a Promise) with
        //the input value from the previous promise. To do this, we have to store
        //its value here redundant, because .Await from the previous promise
        //will Nil the value on Await if this is an object. This is done,
        //because we transfer the ownership of an object on Await (by design).
        SetInputValue(FPreviousPromise.Await);
        Result := FFunc(GetInputValue);
      end);

    //We explicit remove the references to FFunc and FCatchFunc here to prevent reference cycles
    //with anonymous methods and closures, see https://stackoverflow.com/questions/51213638/why-is-this-interface-not-correctly-released-when-the-method-is-exited/51221496#51221496
    //and https://quality.embarcadero.com/browse/RSP-30430
    FCatchFunc := nil;
    FFunc := nil;
  end;
end;

function TPromiseKeepInputValue<T>.GetInputValue: T;
begin
  System.TMonitor.Enter(Self);
  try
    Result := FPreviousValue;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

procedure TPromiseKeepInputValue<T>.SetInputValue(AValue: T);
begin
  System.TMonitor.Enter(Self);
  try
    FPreviousValue := AValue;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

initialization
  CreatePromiseSchedulerIf;

end.
