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
	if(s.isDirective)
	{
		import std.string: strip, split;
		immutable stripped = s.strip;
		immutable keyword = stripped.split[2];

		if (keyword == "include")
		{
			return Directive.Include;
		}

		if (keyword == "call")
		{
			return Directive.Call;
		}

		if (keyword == "echo")
		{
			return Directive.Echo;
		}

		assert(false);
	}

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
