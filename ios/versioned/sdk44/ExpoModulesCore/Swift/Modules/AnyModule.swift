
/**
 A protocol for any type-erased module that provides functions used by the core.
 */
public protocol AnyModule: AnyObject, AnyArgument {
  /**
   The default initializer. Must be public, but the module class does *not* need to
   define it as it is implemented in protocol composition, see `BaseModule` class.
   */
  init(appContext: AppContext)

  /**
   A DSL-like function that returns a `ModuleDefinition` which can be built up from module's name, constants or functions.
   The `@ModuleDefinitionBuilder` wrapper is *not* required in the implementation — it is implicitly taken from the protocol.

   # Example

   ```
   public func definition() -> ModuleDefinition {
     name("MyModule")
     function("myFunction") { (a: String, b: String) in
       "\(a) \(b)"
     }
   }
   ```

   This example exports the module to the JavaScript world, which can be used as in this snippet 👇

   ```javascript
   import { NativeModulesProxy } from 'expo-modules-core';

   await NativeModulesProxy.MyModule.myFunction('Hello', 'World!'); // -> 'Hello World!'
   ```

   # Function's result obtained asynchronously

   If you need to run some async code to get the proper value that you want to return to JavaScript,
   just specify an argument of type `Promise` as the last one and use its `resolve` or `reject` functions.

   ```
   function("myFunction") { (promise: Promise) in
     DispatchQueue.main.async {
       promise.resolve("return value obtained in async callback")
     }
   }
   ```
   */
  #if swift(>=5.4)
  @ModuleDefinitionBuilder
  func definition() -> ModuleDefinition
  #else
  func definition() -> ModuleDefinition
  #endif
}
