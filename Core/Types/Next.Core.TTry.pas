unit Next.Core.TTry;

interface

uses
  System.SysUtils, Next.Core.FailureReason, Next.Core.Promises,
  Next.Core.DisposableValue;

type
  ITry<T> = interface;

  TDisposeValue = (dvFree, dvKeep);

  TTryOp<T> = record
  private
    FTry: ITry<T>;
  public
    class function Create(const ATry: ITry<T>): TTryOp<T>; static;

    function Map<T2>(AFunc: TFunc<T, T2>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T2>; overload;
    function Map<T2>(AFunc: TFunc<T, ITry<T2>>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T2>; overload;
  end;

  ITrySimple = interface
  ['{A582096A-CAE8-4A90-8F9C-27BE5978CF06}']
    function IsSuccess: Boolean;
    function IsFailure: Boolean;
  end;

  ITry<T> = interface(ITrySimple)
  ['{C17C42C4-3732-4F17-805E-908A6927A54E}']
    function GetValue: T;
    procedure RaiseExceptionIf;

    function Map(AFunc: TFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T>; overload;
    function Map(AFunc: TFunc<T, ITry<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T>; overload;

    function Accept(AProc: TProc<T>): ITry<T>;

    function Recover(AFunc: TFunc<Exception, T>): ITry<T>; overload;
    function Recover(AFunc: TFunc<Exception, ITry<T>>): ITry<T>; overload;

    function AssignTo(AProc: TProc<T>): ITrySimple;
    function Fail(AProc: TProc<Exception>): ITry<T>;

    function Resolve: IPromise<T>;

    function Op: TTryOp<T>;

    property Value: T read GetValue;
  end;

  TSuccess<T> = class(TInterfacedObject, ITry<T>, ITrySimple)
  private
    FValue: TDisposableValue<T>;
  protected
    function GetValue: T;
    procedure RaiseExceptionIf;
  public
    constructor Create(AValue: T);
    destructor Destroy; override;

    function Map(AFunc: TFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T>; overload;
    function Map(AFunc: TFunc<T, ITry<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T>; overload;

    function Accept(AProc: TProc<T>): ITry<T>;

    function Recover(AFunc: TFunc<Exception, T>): ITry<T>; overload;
    function Recover(AFunc: TFunc<Exception, ITry<T>>): ITry<T>; overload;

    function AssignTo(AProc: TProc<T>): ITrySimple;
    function Fail(AProc: TProc<Exception>): ITry<T>;

    function Op: TTryOp<T>;

    function Resolve: IPromise<T>;

    function IsSuccess: Boolean;
    function IsFailure: Boolean;
  end;

  TFailure<T> = class(TInterfacedObject, ITry<T>, ITrySimple)
  private
    FFailure: IFailureReason;
  protected
    function GetValue: T;
    procedure RaiseExceptionIf;
  public
    constructor Create(AFailure: IFailureReason);

    function Map(AFunc: TFunc<T, T>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T>; overload;
    function Map(AFunc: TFunc<T, ITry<T>>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T>; overload;

    function Accept(AProc: TProc<T>): ITry<T>;

    function Recover(AFunc: TFunc<Exception, T>): ITry<T>; overload;
    function Recover(AFunc: TFunc<Exception, ITry<T>>): ITry<T>; overload;

    function AssignTo(AProc: TProc<T>): ITrySimple;
    function Fail(AProc: TProc<Exception>): ITry<T>;

    function Op: TTryOp<T>;

    function Resolve: IPromise<T>;

    function IsSuccess: Boolean;
    function IsFailure: Boolean;
  end;

  TTry = class
    class function &Of<T>(AFunc: TFunc<T>): ITry<T>; overload;
    class function &Of<T>(AFunc: TFunc<ITry<T>>): ITry<T>; overload;
  end;

implementation

{ Failure<T> }

function TFailure<T>.Accept(AProc: TProc<T>): ITry<T>;
begin
  Result := Self;
end;

function TFailure<T>.AssignTo(AProc: TProc<T>): ITrySimple;
begin
  Result := Self;
end;

constructor TFailure<T>.Create(AFailure: IFailureReason);
begin
  FFailure := AFailure;
end;

function TFailure<T>.Fail(AProc: TProc<Exception>): ITry<T>;
begin
  Result := Recover(function(E: Exception): T begin AProc(E); raise E; end);
end;

function TFailure<T>.GetValue: T;
begin
  raise FFailure.DetachExceptionObject;
end;

procedure TFailure<T>.RaiseExceptionIf;
begin
  raise FFailure.DetachExceptionObject;
end;

function TFailure<T>.IsFailure: Boolean;
begin
  Result := True;
end;

function TFailure<T>.IsSuccess: Boolean;
begin
  Result := False;
end;

function TFailure<T>.Map(AFunc: TFunc<T, ITry<T>>; ADispose: TDisposeValue): ITry<T>;
begin
  Result := Self;
end;

function TFailure<T>.Op: TTryOp<T>;
begin
  Result := TTryOp<T>.Create(Self);
end;

function TFailure<T>.Recover(AFunc: TFunc<Exception, ITry<T>>): ITry<T>;
var
  LE: Exception;
  LException: TObject;
begin
  LE := FFailure.Reason;
  try
    Result := TSuccess<T>.Create(AFunc(LE).Value);
  except
    on E: Exception do begin
      //If the same exception is re-raised, we must detach the exception
      //object from the previous promise. This raise makes that the
      //exception object is inserted in our IFailureReason-object (which
      //will be destroyed if this Try is destroyed). However, the
      //previous Try also holds a reference to this object and if we
      //do not detach it here, it will be destroybed as the previous
      //Try is destroyed (and then we have a dangling pointer in our
      //IFailureReason-object).
      if E = LE then
        FFailure.DetachExceptionObject;

      LException := AcquireExceptionObject;
      Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
    end;
  end;
end;

function TFailure<T>.Resolve: IPromise<T>;
begin
  Result := Promise.Reject<T>(FFailure.DetachExceptionObject);
end;

function TFailure<T>.Recover(AFunc: TFunc<Exception, T>): ITry<T>;
var
  LE: Exception;
  LException: TObject;
begin
  LE := FFailure.Reason;
  try
    Result := TSuccess<T>.Create(AFunc(LE));
  except
    on E: Exception do begin
      //If the same exception is re-raised, we must detach the exception
      //object from the previous promise. This raise makes that the
      //exception object is inserted in our IFailureReason-object (which
      //will be destroyed if this Try is destroyed). However, the
      //previous Try also holds a reference to this object and if we
      //do not detach it here, it will be destroybed as the previous
      //Try is destroyed (and then we have a dangling pointer in our
      //IFailureReason-object).
      if E = LE then
        FFailure.DetachExceptionObject;

      LException := AcquireExceptionObject;
      Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
    end;
  end;
end;

function TFailure<T>.Map(AFunc: TFunc<T, T>; ADispose: TDisposeValue): ITry<T>;
begin
  Result := Self;
end;

{ Success<T> }

function TSuccess<T>.Accept(AProc: TProc<T>): ITry<T>;
var
  LException: TObject;
begin
  try
    AProc(FValue);
    Result := Self;
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

function TSuccess<T>.AssignTo(AProc: TProc<T>): ITrySimple;
begin
  AProc(FValue);
  FValue.&Nil;
  Result := Self;
end;

constructor TSuccess<T>.Create(AValue: T);
begin
  FValue := AValue;
end;

destructor TSuccess<T>.Destroy;
begin
  FValue.Dispose;
  inherited;
end;

function TSuccess<T>.Fail(AProc: TProc<Exception>): ITry<T>;
begin
  Result := Self;
end;

function TSuccess<T>.GetValue: T;
begin
  Result := FValue;
  FValue.&Nil;
end;

procedure TSuccess<T>.RaiseExceptionIf;
begin
  // No-op
end;

function TSuccess<T>.IsFailure: Boolean;
begin
  Result := False;
end;

function TSuccess<T>.IsSuccess: Boolean;
begin
  Result := True;
end;

function TSuccess<T>.Map(AFunc: TFunc<T, ITry<T>>; ADispose: TDisposeValue): ITry<T>;
var
  LException: TObject;
  LValue: TDisposableValue<T>;
  LNewValue: T;
begin
  try
    LValue := GetValue();
    try
      LNewValue := AFunc(LValue).Value;
      Result := TSuccess<T>.Create(LNewValue);
    finally
      if ADispose = TDisposeValue.dvFree then
        LValue.TryDispose<T>(LNewValue);
    end;
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

function TSuccess<T>.Op: TTryOp<T>;
begin
  Result := TTryOp<T>.Create(Self);
end;

function TSuccess<T>.Recover(AFunc: TFunc<Exception, ITry<T>>): ITry<T>;
begin
  Result := Self;
end;

function TSuccess<T>.Resolve: IPromise<T>;
begin
  Result := Promise.Resolve<T>(GetValue);
end;

function TSuccess<T>.Recover(AFunc: TFunc<Exception, T>): ITry<T>;
begin
  Result := Self;
end;

function TSuccess<T>.Map(AFunc: TFunc<T, T>; ADispose: TDisposeValue): ITry<T>;
var
  LException: TObject;
  LValue: TDisposableValue<T>;
  LNewValue: T;
begin
  try
    LValue := GetValue();
    try
      LNewValue := AFunc(LValue);
      Result := TSuccess<T>.Create(LNewValue);
    finally
      if ADispose = TDisposeValue.dvFree then
        LValue.TryDispose<T>(LNewValue);
    end;
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

{ TTry }

class function TTry.&Of<T>(AFunc: TFunc<T>): ITry<T>;
var
  LException: TObject;
begin
  try
    Result := TSuccess<T>.Create(AFunc());
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

class function TTry.&Of<T>(AFunc: TFunc<ITry<T>>): ITry<T>;
var
  LException: TObject;
begin
  try
    Result := TSuccess<T>.Create(AFunc().Value);
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

{ TTryOp<T> }

class function TTryOp<T>.Create(const ATry: ITry<T>): TTryOp<T>;
begin
  Assert(Assigned(ATry));

  Result.FTry := ATry;
end;

function TTryOp<T>.Map<T2>(AFunc: TFunc<T, T2>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T2>;
var
  LException: TObject;
  LValue: TDisposableValue<T>;
begin
  try
    LValue := FTry.Value;
    try
      Result := TSuccess<T2>.Create(AFunc(LValue));
    finally
      if ADispose = TDisposeValue.dvFree then
        LValue.Dispose;
    end;
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T2>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

function TTryOp<T>.Map<T2>(AFunc: TFunc<T, ITry<T2>>; ADispose: TDisposeValue = TDisposeValue.dvFree): ITry<T2>;
var
  LException: TObject;
  LValue: TDisposableValue<T>;
begin
  try
    LValue := FTry.Value;
    try
      Result := TSuccess<T2>.Create(AFunc(LValue).Value);
    finally
      if ADispose = TDisposeValue.dvFree then
        LValue.Dispose;
    end;
  except
    LException := AcquireExceptionObject;
    Result := TFailure<T2>.Create(TFailureReason.Create(LException as Exception));
  end;
end;

end.
