# Promise Implementation in Delphi

## Overview

This Delphi library implements promises, enabling asynchronous programming by facilitating the handling of operations that may require time to complete. A promise represents a guarantee for an eventual result, streamlining the way asynchronous operations are managed in your applications. Additionally, this implementation embraces monadic principles, offering a structured approach to chaining computations and handling their outcomes.

## Features

- **Promise Chaining:** Easily chain multiple asynchronous operations, passing the result of one as the input to the next.
- **Exception handling:** The promise is side-affect free, so it manages exceptions inside the chain and you are able to recover from them. 
- **Type Transformation:** Transform the resolved value's type through the `.Op` method, enabling flexible data handling.
- **Memory Management:** Control the lifecycle of promise-resolved values with `dvKeep` and `dvFree` directives, ensuring efficient resource utilization.

## Getting Started

To integrate this promise library into your Delphi projects, include the necessary unit in your project source and follow the examples provided below.

### Simple Promise Example

Perform a simple background operation and wait (blocking) for it to complete.

```delphi
uses Next.Core.Promises;

// Create and resolve a simple promise
var
  value: String;
begin
  value := Promise.Resolve<String>(function: String
    begin
      Result := 'Hello, World!';
    end).Await;
 
  // Outputs: Hello, World!
  WriteLn(value);
end;
```

### Keep UI responsive

Perform a simple background operation and show a messagebox on completion while keeping the UI responsive.

```delphi
uses Next.Core.Promises;

// Create and resolve a simple promise
procedure DoHeavyOperationOnButtonClick()
begin
  Promise.Resolve<String>(function: String
    begin
      //Do some heavy operation
      Result := 'Heavy operation completed!';
    end)
  .Main.ThenBy(procedure(const value: String)
    begin
      ShowMessage(value);
    end);

  //Continue your flow, the messagebox will popup when the operation is completed. You might consider showing a indicator that shows that the operation is going on.
end;
```

### Promise Chaining Example

Chain promises to perform a sequence of operations where each step depends on the outcome of the previous one.

```delphi
uses Next.Core.Promises;

// Chain promises to multiply an integer and convert it to a string
// Ensure UI update is on the main thread
begin
  Promise.Resolve<Integer>(function: Integer
    begin
      Result := 10;
    end)
  .ThenBy<Integer>(function(const value: Integer): Integer
    begin
      Result := value * 2; // Process in background thread
    end)
  .Op.ThenBy<String>(function(const value: Integer): String
    begin
      Result := IntToStr(value); // Process in background thread
    end)
  .Main.ThenBy<TVoid>(function(const value: String): TVoid
    begin
      WriteLn(value); // Synchronized to the main thread
      Result := Void;
    end);
end;
```

### Type Transformation with `.Op`

Use the `.Op` method to transform the type of the resolved value of a promise.

```delphi
uses Next.Core.Promises;

// Transform the resolved value type from Integer to String
var promise: IPromise<String>;
begin
  promise := Promise.Resolve<Integer>(function: Integer
    begin
      Result := 10;
    end)
  .Op.ThenBy<String>(function(const value: Integer): String
    begin
      Result := 'Transformed Value: ' + IntToStr(value); // Process in background thread
    end);

  WriteLn(promise.Await); // Outputs: Transformed Value: 10
end;
```

## Exception handling

If any exceptions occurs, the chain will be interrupted until the first `.Catch` in the chain. If there is no catch, the promise will be rejected. Calling `.Await` on a rejected promise will raise the exception that was caught inside the promise in the caller context.

### Recover from exceptions
Use the `.Catch` method to recover from any exception in the chain.

```delphi
uses Next.Core.Promises;

// Handling exceptions and synchronizing error handling to the main thread
begin
  Promise.Resolve<Integer>(function: Integer
    begin
      raise Exception.Create('Simulated error');
    end)
  .Catch<Boolean>(function(E: Exception): Boolean
    begin
      if E.Message = 'Simulated error' then
        Result := False // Recover from the error condition
      else
        raise; // Re-throw for other exceptions
    end)
  .Main.ThenBy<TVoid>(function(const value: Boolean): TVoid
    begin
      if not value then
        WriteLn('Error handled, alternative value provided.'); // UI handling in the main thread
      Result := Void; // Setting result to Void correctly
    end);
end;
```

## Memory Management

By default, the promise is responsible for handling the memory of everything that is returned by any of the anonymous methods. That means that if you create an object in a resolver function, that object is disposed when the promise is disposed.

### Use Await to transfer ownership

With `.Await` you can retrieve the value inside the promise and use it. After calling `.Await` the ownership of the value is transfered to the caller, so -if it is an object- the promise will no longer dispose it.

### Changing the default behavior

Efficiently manage the memory of resolved values within promises using two directives:

- **dvKeep**: Indicates that the promise should transfer ownership of the resolved value and that it is not disposed at the end of the promise' lifecycle. This can be necessary to move objects in another object (for example putting the result of `Promise.All` in a `TObjectList`).
- **dvFree**: Specifies that the promise should take responsibility for freeing the resolved value, suitable for managing the lifecycle of dynamically created objects within asynchronous operations. This is the default behavior.

### Example of Memory Management

In the following example we instruct the promise to **not** dispose the object after adding it to the newly created `TObjectList`.

``` delphi
var
  LObjectList: TObjectList<TMyObject>;
begin
  LObjectList := Promise.Resolve<TMyObject>(function: TMyObject
      begin
        Result := TMyObject.Create('test');
      end)
    .Op.ThenBy<TObjectList<TMyObject>>(function(const o: TMyObject): TObjectList<TMyObject>
      begin
        Result := TObjectList<TMyObject>.Create();
        Result.Add(o)
      end, TDisposeValue.dvKeep)    // Do not dispose the argument 'o' 
    .Catch(function(e: Exception): TObjectList<TMyObject>
      begin
        Result := TObjectList<TMyObject>.Create();
      end)
    .Await;
```

## Extended example: using Promises in Asynchronous Methods

Promises can be elegantly integrated into methods to encapsulate asynchronous operations, offering a streamlined approach to handling such tasks. This section demonstrates how to implement a method that performs an asynchronous operation (like fetching data) and returns a `IPromise<T>` where `T` is the type of the data being fetched.

In this example, we define a method `FetchUserData` within a `TUserRepository` class that simulates fetching user data asynchronously and returns a promise of `TUserData`.

#### Defining the Data Structure

First, define a data structure `TUserData` to hold user information:

```delphi
type
  TUserData = record
    UserID: Integer;
    UserName: String;
    Email: String;
  end;
```

#### Implementing the Asynchronous Method

Next, implement the `FetchUserData` method in the `TUserRepository` class:

```delphi
uses
  Next.Core.Promises;

type
  TUserRepository = class
  public
    function FetchUserData(const UserID: Integer): IPromise<TUserData>;
  end;

function TUserRepository.FetchUserData(const UserID: Integer): IPromise<TUserData>;
begin
  // Return a promise that resolves with the user data
  Result := Promise.Resolve<TUserData>(function: TUserData
    begin
      // Simulate an asynchronous data fetching operation
      Sleep(1000); // Simulate delay
      Result.UserID := UserID;
      Result.UserName := 'John Doe';
      Result.Email := 'johndoe@example.com';
    end);
end;
```

This method returns a `IPromise<TUserData>`, encapsulating the asynchronous fetching operation.

#### Using the Asynchronous Method

To use `FetchUserData`, call the method and handle the result, either by awaiting the promise or by chaining additional operations:

```delphi
var
  UserRepository: TUserRepository;
  UserData: TUserData;
begin
  UserRepository := TUserRepository.Create;
  try
    // Fetch user data and await the promise
    UserData := UserRepository.FetchUserData(123).Await;

    // Use the fetched data, ensuring any UI updates are synchronized with the main thread
    WriteLn('User ID: ' + IntToStr(UserData.UserID));
    WriteLn('User Name: ' + UserData.UserName);
    WriteLn('Email: ' + UserData.Email);
  finally
    UserRepository.Free;
  end;
end;
```

This approach simplifies managing asynchronous operations by encapsulating them within methods that return promises. It demonstrates how to perform asynchronous operations, await their completion, and safely update the UI with the results.

## License

This project is licensed under the MIT License - see the LICENSE file for details.