# Apex Style Guide

This is a collection of best practices for writing Apex code.

---

## Test Classes

### Top-level comment

Each test class should have a comment at the top of the file indicating which
class it is testing. It should only say "Tests for {@link ClassName}".

For example:

```apex
/**
 * Tests for {@link ClassName}.
 */
```

### Parallel execution

All test classes should be configured to run in parallel. This is done by
setting `IsParallel=true` in the `@IsTest` annotation.

For example:

```apex
@IsTest(IsParallel=true)
private class ClassNameTest {
}
```

### Test declarations

Always use the `@IsTest` annotation for test classes and test methods. All test
methods should be defined as `private static void`.

### Test method naming

Test methods should be named in either of the following formats:

- `methodName_expectedOutcome`
- `methodName_testScenario_expectedOutcome`

For example:

```apex
@IsTest
private static void methodName_expectedOutcome() {
}

@IsTest
private static void methodName_testScenario_expectedOutcome() {
}
```

### Test method structure

Follow the "arrange, act, assert" test method structure. All code for each
section should be kept together.

Do not include any comments indicating that the sections start and end. This
should be indicated by separating the sections by a blank line.

For example:

```apex
@IsTest
private static void methodName_expectedOutcome() {
  String param1 = 'foo';
  String param2 = 'bar';

  String actual = className.methodName(param1, param2);

  Assert.areEqual(expected, actual);
}
```

### Setting up the class under test

The class under test should be declared as the first local variable in the test.
It should be defined as `private static final ClassName className;`. It's
possible that the class under test is the implementation of an interface. In
this case, the class under test should be declared as
`private static final ClassNameImpl className`.

For example:

```apex
@IsTest(IsParallel=true)
private class ClassNameTest {
  private static final ClassName className;

  static {
    className = new ClassNameImpl();
  }
}
```

When the class under test requires a dependency, the dependency should be
declared as the second local variable in the test. It should be defined as
`private static final DependencyNameMock dependencyName;`. Assume that a Mock
implementation of the dependency already exists.

For example:

```apex
@IsTest(IsParallel=true)
private class ClassNameTest {
  private static final ClassName className;
  private static final DependencyNameMock dependencyName;

  static {
    dependencyName = new DependencyNameMock();

    className = new ClassNameImpl(dependencyName);
  }
}
```

### Mocking dependencies

Assume that a Mock implementation of the dependency already exists.

Each Mock will have a `public final` field called `method`. It can be used to
retrieve the name of each method so that it can be used to supply the method
name to the mock or verify.

Mock method calls by using `.when(String methodName)`. Chain this call with
`.thenReturn(Object result)`, `.thenReturnVoid()`, or
`thenThrow(Exception exception)`.

Verify methods were called by using `.verify(String methodName)`. There is also
an overload to specify the number of times, which is
`.verify(String methodName, Integer times)`. There is also
`never(String methodName)` to verify that a method was not called.

If the test needs to inspect the arguments used to call a mocked method, use
`.getCalls(String methodName)`. This returns a `List<Map<String, Object>>` where
each map contains the name of the argument and its value.

For example:

```apex
@IsTest(IsParallel=true)
private class ClassNameTest {
  private static final ClassName className;
  private static final DependencyNameMock dependencyName;

  static {
    dependencyName = new DependencyNameMock();

    className = new ClassNameImpl(dependencyName);
  }

  @IsTest
  private static void methodName_expectedOutcome() {
    dependencyName.when(dependencyName.method.run()).thenReturnVoid();

    className.methodName();

    dependencyName.verify(dependencyName.method.run());
  }
}
```

### Asserting results

Always use the `Assert` class to assert results. All assertions should be
declared as `Assert.areEqual(expected, actual, message)`. If the `message` is
not useful, omit it.

For example:

```apex
@IsTest
private static void methodName_expectedOutcome() {
  String expected = 'Test';

  String actual = className.methodName();

  Assert.areEqual(expected, actual);
}
```

### Testing exceptions

Use the `AssertThrows` class to assert that an exception is thrown. This class
has a `public static` method called `with(Type exceptionClass)` that returns a
`Throwing` object. There is an overload for
`with(Type exceptionClass, String message)` to specify the exception message.

Use a `try / catch` block to execute the code. If an exception should have been
thrown, call the `shouldHaveThrown` method on the `Throwing` object.

This object has a `public void threw(Exception e)` method that needs to be
called in the `catch` block of the test method. This happens in the "act"
section of the "arrange, act, assert" test method structure.

Call either the `assertHasThrown` or `assertHasNotThrown` method on the
`Throwing` object to assert that the expected behavior occurred.

For example:

```apex
@IsTest
private static void methodName_expectedOutcome() {
  String param1 = null;
  AssertThrows.Throwing throwing = AssertThrows.with(IllegalArgumentException.class, 'param1 is required.');

  try {
    className.methodName(param1);
    throwing.shouldHaveThrown();
  } catch (Exception e) {
    throwing.threw(e);
  }

  throwing.assertHasThrown();
}
```
