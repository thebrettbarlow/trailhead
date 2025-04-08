# Apex Style Guide

This is a collection of best practices for writing Apex code.

---

## Builder Pattern

We prefer to use the Builder pattern when creating objects. This allows us to
create complex objects in a more readable way.

```apex
/**
 * Example class used to demonstrate the Builder pattern.
 */
public with sharing class Example {
  private final String message;

  private Example(Builder builder) {
    this.message = builder.message;
  }

  public String getMessage() {
    return message;
  }

  public static Builder newBuilder() {
    return new Builder();
  }

  public Builder toBuilder() {
    return new Builder().setMessage(this.message);
  }

  public class Builder {
    private String message;

    private Builder() {
    }

    public Builder setMessage(String message) {
      this.message = message;
      return this;
    }

    public Example build() {
      return new Example(this);
    }
  }
}
```

### Test classes for Builder Pattern

We will write test classes that verify the Builder pattern sets the expected
values in the object. For example:

```apex
/**
 * Tests for {@link Example}.
 */
@IsTest(IsParallel=true)
private class ExampleTest {
  @IsTest
  private static void newBuilder_setsAllFields_fieldsHaveExpectedValues() {
    Example example = Example.newBuilder().setMessage('Hello').build();

    Assert.areEqual('Hello', example.getMessage());
  }

  @IsTest
  private static void toBuilder_updatesField_fieldHasExpectedValue() {
    Example example = Example.newBuilder().setMessage('Hello').build();

    Example updatedExample = example.toBuilder().setMessage('World').build();

    Assert.areEqual('World', updatedExample.getMessage());
  }
}
```

## Mock Classes

The `Mock` class can be `extended` to provide mock implementations for any
interface. This allows for easy unit testing because we can mock the behavior of
any interface.

All mock classes should be named with `Mock` after the interface name. For
example: `HelloWorldMock`, `ExampleMock`.

Here is a full example:

```apex
/**
 * {@link Mock} implementation of {@link HelloWorld}.
 */
@IsTest
@SuppressWarnings('PMD.CognitiveComplexity')
public class HelloWorldMock extends Mock implements HelloWorld {
  public final Method method = new Method();

  public String sayHello(String message) {
    return (String) mockedCall(
      method.getUrlPrefix(),
      new Map<String, Object>{ 'message' => message }
    );
  }

  public class Method {
    public String sayHello() {
      return new ExecutionInfo().getFullName();
    }
  }
}
```

## Repository Classes

A repository class consists of the following:

- Interface (`EntityRepo`)
- Implementation (`EntityRepoImpl`)
- Implementation Test (`EntityRepoImplTest`)
- Mock (`EntityRepoMock`)

We will cover each type of class below:

### Interface

#### Class naming

All repository classes should be named in the format `EntityRepo`, with `Entity`
being the name of the entity. For example: `AccountRepo`, `CustomObjectRepo`.

#### Top-level comment

Each repository class should have a comment at the top of the file indicating
that it handles data access for the given entity. For example:

```apex
/**
 * Handles data access for {@link Entity}.
 */
```

#### Method-level comments

Only include a description of the method. Do not include `@param` or `@return`
comments. For example:

```apex
/**
 * Returns the entity with the given id.
 */
Entity getEntityById(Id entityId);
```

#### Methods

When creating a new repository interface, start it with the following methods:

- `getEntityById(Id entityId)`: Returns the entity with the given id.
- `getEntitiesByIds(Set<Id> entityIds)`: Returns the entities with the given
  ids.
- `getEntityByName(String entityName)`: Returns the entity with the given name.
- `getEntitiesByName(String entityName)`: Returns the entities with the given
  name.
- `getEntitiesByNames(Set<String> entityNames)`: Returns the entities with the
  given names.
- `insertEntities(List<Entity> entities)`: Inserts the given entities.
- `updateEntities(List<Entity> entities)`: Updates the given entities.
- `upsertEntities(List<Entity> entities)`: Upserts the given entities.
- `deleteEntities(List<Entity> entities)`: Deletes the given entities.
- `undeleteEntities(List<Entity> entities)`: Undeletes the given entities.

Here is a full example:

```apex
/**
 * Handles data access for {@link Entity}.
 */
public interface EntityRepo {
  /**
   * Returns the entity with the given id.
   */
  Entity getEntityById(Id entityId);

  /**
   * Returns the entities with the given ids.
   */
  List<Entity> getEntitiesByIds(Set<Id> entityIds);

  /**
   * Returns the entity with the given name.
   */
  Entity getEntityByName(String entityName);

  /**
   * Returns the entities with the given name.
   */
  List<Entity> getEntitiesByName(String entityName);

  /**
   * Returns the entities with the given names.
   */
  List<Entity> getEntitiesByNames(Set<String> entityNames);

  /**
   * Inserts the given entities.
   */
  void insertEntities(List<Entity> entities);

  /**
   * Updates the given entities.
   */
  void updateEntities(List<Entity> entities);

  /**
   * Upserts the given entities.
   */
  void upsertEntities(List<Entity> entities);

  /**
   * Deletes the given entities.
   */
  void deleteEntities(List<Entity> entities);

  /**
   * Undeletes the given entities.
   */
  void undeleteEntities(List<Entity> entities);
}
```

### Implementation

#### Class naming

All repository implementations should be named in the format `EntityRepoImpl`,
with `Entity` being the name of the entity. For example: `AccountRepoImpl`,
`CustomObjectRepoImpl`.

#### Top-level comment

Each repository implementation should have a comment at the top of the file
indicating that it is the implementation of the interface for the given entity.
For example:

```apex
/**
 * Implementation of {@link EntityRepo}.
 */
```

#### Access modifiers

The top-level class should be `public` and use the `with sharing` modifier. For
example:

```apex
public with sharing class EntityRepoImpl implements EntityRepo {
}
```

#### Run in user mode

To prevent the `ApexCRUDViolation` PMD finding, all DML operations and SOQL
queries need to run in user mode. For example:

##### DML Operation in User Mode

```apex
public void insertEntities(List<Entity> entities) {
  insert as user entities;
}
```

##### SOQL Query in User Mode

```apex
public List<Entity> getEntitiesByIds(Set<Id> entityIds) {
  return [
    SELECT Id
    FROM Entity
    WHERE Id IN :entityIds
    WITH USER_MODE
  ];
}
```

### Implementation Test Methods

Repository implementations will have either of the following types of tests:

- Asserts that the query ran
- Asserts that the DML operation was performed

We do not care about asserting that specific behavior happened. We only care
that the code ran. Do not create sample records for the test methods to use.

Here is an example of each type of test:

```apex
@IsTest
private static void getEntityById_runsQuery() {
    Id entityId = SObjectIds.generateFakeId(Entity.SObjectType);

    entityRepo.getEntityById(entityId);

    Assert.areEqual(1, Limits.getQueries());
}

@IsTest
private static void insertEntities_performsDml() {
    List<Entity> entities = new List<Entity>();

    try {
      entityRepo.insertEntities(entities);
    } catch (Exception e) {
      System.debug('Preventing the test from failing due to a DML exception');
    } finally {
      Assert.isTrue(Limits.getDmlStatements() > 0);
    }
}
```

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
