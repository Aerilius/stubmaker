=begin
This class can write any Modules/Classes from memory into Ruby code.
It includes constants, class variables, public class methods and public instants
methods. However, methods will not contain any code (they are empty stubs without
return value), but it can satisfy scripts that require these modules/methods.

Usage:

file = File.expand_path("sketchup.rb")
File.open($file,"w"){|f|
  f.puts(StubMaker.dump(Sketchup))
  4.times{f.puts ""}
  f.puts(StubMaker.dump(Geom))
  4.times{f.puts ""}
  f.puts(StubMaker.dump(UI))
}
=end

class StubMaker

  def self.dump(mod)
    return self.new(mod).to_s
  end


  @@indenation = "  "
  def initialize(mod)
    return raise("Argument must be a class or module") unless mod.is_a?(Module)
    @string = ""
    @indentation_level = 0
    @nesting = ""
    dump_module(mod)
  end


  def to_s
    return @string
  end

  private

  # Write data into a line and indent it correctly.
  def add_line(s=nil)
    @string << "\n#{@@indenation * @indentation_level}#{s}"
  end

  # Walks through the contents of a module and generates correspsonding code.
  def dump_module(mod)
    # Module / Class declaration
    modulename = mod.name.sub(@nesting+"::", "")
    # Class
    if mod.is_a?(Class)
      superclass = mod.superclass
      superclass = (!superclass.nil? && superclass != Object) ? " < "+superclass.name : ""
      add_line("class #{modulename}#{superclass}")
    # Module
    else
      add_line("module #{modulename}")
    end
    @indentation_level += 1
    add_line

    # Includes
    # Collect constants and methods of included modules so we can skip them later.
    included_constants = []
    included_methods = []
    included_instance_methods = []
    # Included modules, but not those of a superclass.
    included = mod.included_modules
    included -= mod.superclass.included_modules if mod.is_a?(Class) && mod.superclass
    if !included.empty?
      included.reverse.each{|included_mod|
        add_line("include #{included_mod.name}")
        included_constants.push(*included_mod.constants)
        included_methods.push(*included_mod.methods)
        included_instance_methods.push(*included_mod.instance_methods)
      }
      add_line
    end

    # Constants
    constants = mod.constants - included_constants
    # Collect and exclude constants that are nested modules (or classes).
    nested_mods = []
    if !constants.empty?
      add_line("# Constants")
      constants.sort.each{|constant| # TODO: includes included modules' constants
        value = mod.const_get(constant)
        if value.is_a?(Module)
          nested_mods << value
        else
          add_line("#{constant} = #{value}")
        end
      }
      add_line
    end

    # Class variables
    class_variables = mod.class_variables
    if !class_variables.empty?
      add_line("# Class variables")
      class_variables.sort.each{|variable|
        add_line("@@#{variable} = #{mod.class_variable_get(variable)}")
      }
      add_line
    end

    # Class/module methods
    class_methods = mod.methods - included_methods - Object.methods
    if !class_methods.empty?
      add_line("# Class methods")
      class_methods.sort.each{|methodname|
        dump_method(methodname, mod.method(methodname), "self")
        add_line
      }
    end

    # Instance methods
    instance_methods = mod.instance_methods - included_instance_methods - Object.instance_methods
    if !instance_methods.empty?
      add_line("# Instance methods")
      instance_methods.sort.each{|methodname|
        dump_method(methodname, mod.instance_method(methodname))
        add_line
      }
    end

    # Nested classes/modules
    outer = @nesting
    @nesting = mod.name
    if !nested_mods.empty?
      # Sort the modules by inheritance
      temp, nested_mods = nested_mods, nested_mods.find_all{|m| !m.is_a?(Class) || !nested_mods.include?(m.superclass)}
      temp.each{|m|
        if m.is_a?(Class)
          if nested_mods.include?(m.superclass)
            i = nested_mods.index(m.superclass) || -1
            nested_mods.insert(i+1, m)
          end
        end
      }
      # Generate code.
      nested_mods.each{|m|
        dump_module(m)
        add_line
      }
    end
    @nesting = outer

    @indentation_level -= 1
    if mod.is_a?(Class)
      add_line("end # class #{modulename}")
    else
      add_line("end # module #{modulename}")
    end
  end


  def dump_method(methodname, method=nil, receiver=nil)
    receiver = (receiver.nil?) ? "" : "#{receiver}."
    args = ""
    if (method.is_a?(Method) || method.is_a?(UnboundMethod)) && (arity=method.arity)!=0
      if arity == -1
        args = "(*args)"
      else
        args << "("
        arity.times{|i| args << "arg#{i}"; args << ", " unless i == arity-1 }
        args << ")"
      end
    end
    add_line("def #{receiver}#{methodname}#{args}")
    # We don't know the content of the method, nor the type of return value.
    add_line("end")
  end

end # class StubMaker
