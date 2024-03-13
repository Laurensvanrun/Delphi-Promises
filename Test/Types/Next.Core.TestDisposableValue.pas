unit Next.Core.TestDisposableValue;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDisposableValue = class
    [Test] procedure New();
    [Test] procedure DisposeObject();
    [Test] procedure DisposeInterface();
    [Test] procedure DisposeInteger();
    [Test] procedure NilInteger();
    [Test] procedure NilObject();
    [Test] procedure TryDisposeSameObject();
    [Test] procedure TryDisposeDifferentObject();
    [Test] procedure TryDisposeDifferentClass();
    [Test] procedure VoidShouldWork();
    [Test] procedure TryDisposeArray;
    [Test] procedure DisposeArray;
    [Test] procedure TryDisposeArrayDoesNotTouchOneElement;
    [Test] procedure NilArrayOfObjectsDoesNotDisposeObjects;
    [Test] procedure DisposeArrayShouldNotDisposeItemsInOther;
    [Test] procedure DisposeArrayShouldNotDisposeItemsIfAllInOther;
    [Test] procedure DisposeArrayShouldDisposeItemsInArrayIfOtherIsEmptyArray;
    [Test] procedure DisposeArrayShouldNotDisposeItemIfOneItemIsTheOnlyInOther;
    [Test] procedure DisposeSameObjectOfDifferentTypeShouldNotDisposeIt;
  end;

  TClassToDisposeOrNot = class(TObject)
  private
    FName: String;
  public
    constructor Create(const AName: String); reintroduce;
    property Name: String read FName write FName;
  end;

implementation

uses
  Next.Core.DisposableValue, Next.Core.Void;

{ TTestDisposableValue }

procedure TTestDisposableValue.NilArrayOfObjectsDoesNotDisposeObjects;
const
  OBJ_1 = 'This will go';
  OBJ_2 = 'This will stay';
var
  LValue: TDisposableValue<TArray<TClassToDisposeOrNot>>;
  LObject1, LObject2: TClassToDisposeOrNot;
begin
  LObject1 := nil;
  LObject2 := nil;

  try
    LObject1 := TClassToDisposeOrNot.Create(OBJ_1);
    LObject2 := TClassToDisposeOrNot.Create(OBJ_2);
    LValue := [LObject1, LObject2];
    LValue.&Nil;
    LValue.Dispose;

    Assert.AreEqual(OBJ_1, LObject1.Name);
    Assert.AreEqual(OBJ_2, LObject2.Name);
  finally
    LObject1.Free;
    LObject2.Free;
  end;
end;

procedure TTestDisposableValue.NilInteger;
var
  LValue: TDisposableValue<Integer>;
begin
  LValue := 3;
  LValue.&Nil;
  Assert.AreEqual<Integer>(3, LValue);
end;

procedure TTestDisposableValue.NilObject;
var
  o1, o2: TObject;
  LValue: TDisposableValue<TObject>;
begin
  o1 := TObject.Create;
  try
    LValue := o1;
    LValue.&Nil;
    o2 := LValue;
    Assert.IsNull(o2);
  finally
    o1.Free;
  end;
end;

procedure TTestDisposableValue.TryDisposeDifferentClass;
var
  o1: TObject;
  o2: TInterfacedObject;
  LValue: TDisposableValue<TObject>;
begin
  o1 := TObject.Create;
  o2 := TInterfacedObject.Create;
  try
    LValue := o1;
    LValue.TryDispose(o2);
    Assert.IsNull(TObject(LValue));
  finally
    o2.Free;
  end;
end;

procedure TTestDisposableValue.TryDisposeDifferentObject;
var
  o1, o2: TObject;
  LValue: TDisposableValue<TObject>;
begin
  o1 := TObject.Create;
  o2 := TObject.Create;
  try
    LValue := o1;
    LValue.TryDispose(o2);
    Assert.IsNull(TObject(LValue));
  finally
    o2.Free;
  end;
end;

procedure TTestDisposableValue.TryDisposeSameObject;
var
  o1, o2: TObject;
  LValue: TDisposableValue<TObject>;
begin
  o1 := TObject.Create;
  o2 := o1;
  try
    LValue := o1;
    LValue.TryDispose<TObject>(o2);
    Assert.IsNotNull(TObject(LValue));
  finally
    o1.Free;
  end;
end;

procedure TTestDisposableValue.VoidShouldWork;
var
  LValue: TDisposableValue<TVoid>;
begin
  LValue := Void;
  LValue.TryDispose(Void);
end;

procedure TTestDisposableValue.TryDisposeArray;
var
  LValue: TDisposableValue<TArray<TObject>>;
  LArray: TArray<TObject>;
  LObject1, LObject2: TObject;
begin
  LObject1 := TObject.Create;
  LObject2 := TObject.Create;
  LValue := [LObject1, LObject2];
  LValue.TryDispose<TObject>(nil);
  LArray := LValue;

  Assert.AreEqual(2, Length(LArray)); //The pointers should still be there, but nil
  Assert.IsNull(LArray[0]);
  Assert.IsNull(LArray[1]);
end;

procedure TTestDisposableValue.DisposeArray;
var
  LValue: TDisposableValue<TArray<TObject>>;
  LArray: TArray<TObject>;
  LObject1, LObject2: TObject;
begin
  LObject1 := TObject.Create;
  LObject2 := TObject.Create;
  LValue := [LObject1, LObject2];
  LValue.Dispose;
  LArray := LValue;

  Assert.IsNull(LArray[0]);
  Assert.IsNull(LArray[1]);
end;

procedure TTestDisposableValue.TryDisposeArrayDoesNotTouchOneElement;
const
  OBJ_1 = 'This will go';
  OBJ_2 = 'This will stay';
var
  LValue: TDisposableValue<TArray<TClassToDisposeOrNot>>;
  LObject1, LObject2: TClassToDisposeOrNot;
begin
  LObject2 := nil;
  try
    LObject1 := TClassToDisposeOrNot.Create(OBJ_1);
    LObject2 := TClassToDisposeOrNot.Create(OBJ_2);
    LValue := [LObject1, LObject2];
    LValue.TryDispose<TClassToDisposeOrNot>(LObject2);

    Assert.AreEqual(OBJ_2, LObject2.Name);
  finally
    LObject2.Free;
  end
end;

procedure TTestDisposableValue.DisposeArrayShouldDisposeItemsInArrayIfOtherIsEmptyArray;
const
  OBJ_1 = 'This will go';
  OBJ_2 = 'This will go as well';
var
  LValue, LValueOther: TDisposableValue<TArray<TClassToDisposeOrNot>>;
begin
  var LObject1 := TClassToDisposeOrNot.Create(OBJ_1);
  var LObject2 := TClassToDisposeOrNot.Create(OBJ_2);

  LValue := [LObject1, LObject2];
  LValueOther := [];
  LValue.TryDispose<TArray<TClassToDisposeOrNot>>(LValueOther);

  Assert.AreEqual<TClassToDisposeOrNot>(nil, TArray<TClassToDisposeOrNot>(LValue)[0]);
  Assert.AreEqual<TClassToDisposeOrNot>(nil, TArray<TClassToDisposeOrNot>(LValue)[1]);
end;

procedure TTestDisposableValue.DisposeArrayShouldNotDisposeItemIfOneItemIsTheOnlyInOther;
const
  OBJ_1 = 'This will stay';
var
  LValue, LValueOther: TDisposableValue<TArray<TClassToDisposeOrNot>>;
begin
  var LObject1 := TClassToDisposeOrNot.Create(OBJ_1);

  LValue := [LObject1];
  LValueOther := [LObject1];
  LValue.TryDispose<TArray<TClassToDisposeOrNot>>(LValueOther);

  Assert.AreEqual<TClassToDisposeOrNot>(LObject1, TArray<TClassToDisposeOrNot>(LValue)[0]);
  Assert.AreEqual<TClassToDisposeOrNot>(LObject1, TArray<TClassToDisposeOrNot>(LValueOther)[0]);

  //LObject1 was in LValueOther, so it shouldn't be destroyed. We have to clean it up ourselves
  LObject1.Free;
end;

procedure TTestDisposableValue.DisposeArrayShouldNotDisposeItemsIfAllInOther;
const
  OBJ_1 = 'This will go';
  OBJ_2 = 'This will stay';
var
  LValue, LValueOther: TDisposableValue<TArray<TClassToDisposeOrNot>>;
begin
  var LObject1 := TClassToDisposeOrNot.Create(OBJ_1);
  var LObject2 := TClassToDisposeOrNot.Create(OBJ_2);

  LValue := [LObject1, LObject2];
  LValueOther := [LObject2, LObject1];
  LValue.TryDispose<TArray<TClassToDisposeOrNot>>(LValueOther);

  Assert.AreEqual<TClassToDisposeOrNot>(LObject1, TArray<TClassToDisposeOrNot>(LValue)[0]);
  Assert.AreEqual<TClassToDisposeOrNot>(LObject2, TArray<TClassToDisposeOrNot>(LValue)[1]);

  Assert.AreEqual<TClassToDisposeOrNot>(LObject2, TArray<TClassToDisposeOrNot>(LValueOther)[0]);
  Assert.AreEqual<TClassToDisposeOrNot>(LObject1, TArray<TClassToDisposeOrNot>(LValueOther)[1]);

  //LObject1 was in LValueOther, so it shouldn't be destroyed. We have to clean it up ourselves
  LObject1.Free;
  LObject2.Free;
end;

procedure TTestDisposableValue.DisposeArrayShouldNotDisposeItemsInOther;
const
  OBJ_1 = 'This will go';
  OBJ_2 = 'This will stay';
var
  LValue, LValueOther: TDisposableValue<TArray<TClassToDisposeOrNot>>;
begin
  var LObject1 := TClassToDisposeOrNot.Create(OBJ_1);
  var LObject2 := TClassToDisposeOrNot.Create(OBJ_2);

  LValue := [LObject1, LObject2];
  LValueOther := [LObject1];
  LValue.TryDispose<TArray<TClassToDisposeOrNot>>(LValueOther);

  Assert.AreEqual<TClassToDisposeOrNot>(LObject1, TArray<TClassToDisposeOrNot>(LValue)[0]);
  Assert.AreEqual<TClassToDisposeOrNot>(nil, TArray<TClassToDisposeOrNot>(LValue)[1]);

  Assert.AreEqual<TClassToDisposeOrNot>(LObject1, TArray<TClassToDisposeOrNot>(LValueOther)[0]);

  //LObject1 was in LValueOther, so it shouldn't be destroyed. We have to clean it up ourselves
  LObject1.Free;
end;

procedure TTestDisposableValue.DisposeInteger;
var
  LValue: TDisposableValue<Integer>;
begin
  LValue := 3;
  LValue.Dispose;
  Assert.AreEqual<Integer>(3, LValue);
end;

procedure TTestDisposableValue.DisposeInterface;
var
  o: IInterface;
  LValue: TDisposableValue<IInterface>;
begin
  o := TInterfacedObject.Create;
  LValue := o;
  LValue.Dispose;
  Assert.AreEqual<IInterface>(o, LValue);
end;

procedure TTestDisposableValue.DisposeObject;
var
  o: TObject;
  LValue: TDisposableValue<TObject>;
begin
  LValue := TObject.Create;
  LValue.Dispose;
  o := LValue;
  Assert.IsNull(o);
end;

procedure TTestDisposableValue.DisposeSameObjectOfDifferentTypeShouldNotDisposeIt;
begin
  var o1 := TClassToDisposeOrNot.Create('test');
  var LValue: TDisposableValue<TClassToDisposeOrNot> := o1;
  try
    var o2: TObject := o1;
    LValue.TryDispose<TObject>(o2);
    Assert.IsNotNull(TObject(LValue));
  finally
    LValue.Dispose;
  end;
end;

procedure TTestDisposableValue.New;
var
  LValue: TDisposableValue<TObject>;
  o: TObject;
begin
  Assert.WillRaise(procedure begin o := LValue; end);
  LValue := TObject.Create;
  Assert.WillNotRaise(procedure begin o := LValue; o.Free; end);
end;

{ TClassToDisposeOrNot }

constructor TClassToDisposeOrNot.Create(const AName: String);
begin
  inherited Create;

  FName := AName;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDisposableValue);

end.
