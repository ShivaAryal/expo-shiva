import ExpoModulesTestCore

@testable import ExpoModulesCore

class ClassComponentSpec: ExpoSpec {
  override func spec() {
    describe("module class") {
      let appContext = AppContext.create()
      let runtime = appContext.runtime

      beforeSuite {
        class ClassTestModule: Module {
          func definition() -> ModuleDefinition {
            Name("ClassTest")

            Class("MyClass") {
              Constructor {
              }

              Function("myFunction") {
                return "foobar"
              }

              Property("foo") {
                return "bar"
              }
            }
          }
        }
        appContext.moduleRegistry.register(moduleType: ClassTestModule.self)
      }

      it("is a function") {
        let klass = try runtime?.eval("ExpoModules.ClassTest.MyClass")
        expect(klass?.isFunction()) == true
      }

      it("has a name") {
        let klass = try runtime?.eval("ExpoModules.ClassTest.MyClass.name")
        expect(klass?.getString()) == "MyClass"
      }

      it("has a prototype") {
        let prototype = try runtime?.eval("ExpoModules.ClassTest.MyClass.prototype")
        expect(prototype?.isObject()) == true
      }

      it("has keys in prototype") {
        let prototypeKeys = try runtime?.eval("Object.keys(ExpoModules.ClassTest.MyClass.prototype)")
          .getArray()
          .map { $0.getString() } ?? []

        expect(prototypeKeys).to(contain("myFunction"))
        expect(prototypeKeys).notTo(contain("__native_constructor__"))
      }

      it("is an instance of") {
        try runtime?.eval("myObject = new ExpoModules.ClassTest.MyClass()")
        let isInstanceOf = try runtime?.eval("myObject instanceof ExpoModules.ClassTest.MyClass")

        expect(isInstanceOf?.getBool()) == true
      }

      it("defines properties on initialization") {
        // The properties are not specified in the prototype, but defined during initialization.
        let object = try runtime?.eval("new ExpoModules.ClassTest.MyClass()").asObject()
        expect(object?.getPropertyNames()).to(contain("foo"))
        expect(object?.getProperty("foo").getString()) == "bar"
      }
    }
  }
}
