// Copyright 2022-present 650 Industries. All rights reserved.

public final class ClassComponent: ObjectDefinition {
  let name: String

  let constructor: AnySyncFunctionComponent?

  init(name: String, children: [ClassComponentChild]) {
    self.name = name
    self.constructor = children.first(where: isConstructor) as? AnySyncFunctionComponent

    // Constructors can't be passed down to the object component
    // as we shouldn't override the default `<Class>.prototype.constructor`.
    let childrenWithoutConstructors = children.filter({ !isConstructor($0) })

    super.init(definitions: childrenWithoutConstructors)
  }

  // MARK: - JavaScriptObjectBuilder

  public override func build(inRuntime runtime: JavaScriptRuntime) -> JavaScriptObject {
    let klass = runtime.createClass(name) { [weak self, weak runtime] caller, args in
      guard let self = self, let runtime = runtime else {
        // TODO: Throw an exception? (@tsapeta)
        return
      }
      self.decorateWithProperties(runtime: runtime, object: caller)
      let _ = try? self.constructor?.call(args: args)
    }
    decorate(object: klass, inRuntime: runtime)
    return klass
  }

  public override func decorate(object: JavaScriptObject, inRuntime runtime: JavaScriptRuntime) {
    // Here we actually don't decorate the input object (constructor) but its prototype.
    // Properties are intentionally skipped here — they have to decorate an instance instead of the prototype.
    let prototype = object.getProperty("prototype").getObject()
    decorateWithConstants(runtime: runtime, object: prototype)
    decorateWithFunctions(runtime: runtime, object: prototype)
    decorateWithClasses(runtime: runtime, object: prototype)
  }
}

// MARK: - Component child

public protocol ClassComponentChild: AnyDefinition {}

extension PropertyComponent: ClassComponentChild {}

// MARK: - Class builder

@resultBuilder
public struct ClassComponentBuilder {
  public static func buildBlock(_ children: ClassComponentChild...) -> [ClassComponentChild] {
    return children
  }
}

// MARK: - Factory functions

/**
 Class constructor without arguments.
 */
public func Constructor(_ body: @escaping () throws -> ()) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Class constructor with one argument.
 */
public func Constructor<A0: AnyArgument>(_ body: @escaping (A0) throws -> ()) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Class constructor with two arguments.
 */
public func Constructor<A0: AnyArgument, A1: AnyArgument>(_ body: @escaping (A0, A1) throws -> ()) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Class constructor with three arguments.
 */
public func Constructor<A0: AnyArgument, A1: AnyArgument, A2: AnyArgument>(
  _ body: @escaping (A0, A1, A2) throws -> ()
) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Class constructor with four arguments.
 */
public func Constructor<A0: AnyArgument, A1: AnyArgument, A2: AnyArgument, A3: AnyArgument>(
  _ body: @escaping (A0, A1, A2, A3) throws -> ()
) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Class constructor with five arguments.
 */
public func Constructor<A0: AnyArgument, A1: AnyArgument, A2: AnyArgument, A3: AnyArgument, A4: AnyArgument>(
  _ body: @escaping (A0, A1, A2, A3, A4) throws -> ()
) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Class constructor with six arguments.
 */
public func Constructor<A0: AnyArgument, A1: AnyArgument, A2: AnyArgument, A3: AnyArgument, A4: AnyArgument, A5: AnyArgument>(
  _ body: @escaping (A0, A1, A2, A3, A4, A5) throws -> ()
) -> AnyFunction {
  return Function("constructor", body)
}

/**
 Creates the class
 */
public func Class(_ name: String, @ClassComponentBuilder _ children: () -> [ClassComponentChild]) -> ClassComponent {
  return ClassComponent(name: name, children: children())
}

// MARK: - Privates

fileprivate func isConstructor(_ item: AnyDefinition) -> Bool {
  return (item as? AnySyncFunctionComponent)?.name == "constructor"
}
