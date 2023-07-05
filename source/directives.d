module sitegen.directives;

enum Directive
{
	None, //normal text
	Include,
	Call,
	Echo
}

struct StringAndDirective
{
	Directive d;
	string s;
}

Directive stringToDirective(in string s) pure @safe
{
	if(s.isIncludeDirective)
	{
		return Directive.Include;
	}
	//else if(s.isBuiltInDirective)
	//{
	//	return Directive.BuiltIn;
	//}
	//else if(s.isBuiltInDirective)
	//{
	//	return Directive.Function;
	//}

	return Directive.None;
}

StringAndDirective parse(in string s) pure @safe
{
	StringAndDirective result;

	result.d = stringToDirective(s);
	if(result.d == Directive.Include)
	{
		import std.array: split;
		foreach(include; split(s)[3 .. $-1])
		result.s ~= include;
	}
	return result;
}

bool isDirective(in string s) pure @safe
{
	import std.string: strip, startsWith, endsWith;
	immutable stripped = s.strip;
	return stripped.startsWith("<!-- sitegen ") && stripped.endsWith(" -->");
}

bool isIncludeDirective(in string s) pure @safe
{
	import std.string: strip, startsWith, endsWith;
	immutable stripped = s.strip;
	return stripped.startsWith("<!-- sitegen include ") && stripped.endsWith(" -->");
}
