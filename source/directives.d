module sitegen.directives;

enum Directive
{
	None, //normal text
	Include,
	Call,
	Echo,
	Time
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

		if (keyword == "time")
		{
			return Directive.Time;
		}

		assert(false);
	}

	return Directive.None;
}

StringAndDirective parse(in string s) pure @safe
{
	StringAndDirective result;

	result.d = stringToDirective(s);
	final switch (result.d) with (Directive)
	{
		case Include: result.s = parseIncludeDirective(s); break;
		case Call: result.s = parseCallDirective(s); break;
		case Echo: result.s = parseEchoDirective(s); break;
		case Time: break;
		case None: break;
	}

	return result;
}

string parseIncludeDirective(in string s) pure @safe
{
	string result;
	import std.array: split;
	return split(s)[3];
}

string parseCallDirective(in string s) pure @safe
{
	string result;
	import std.array: split;
	foreach(arg; split(s)[3 .. $-1])
	{
		result ~= arg ~ " ";
	}
	return result;
}

string parseEchoDirective(in string s) pure @safe
{
	string result;
	import std.array: split;
	foreach(echo; split(s)[3 .. $-1])
	{
		result ~= echo ~ " ";
	}
	return result;
}

bool isDirective(in string s) pure @safe
{
	bool result = true;
	import std.string: strip, startsWith, endsWith;
	import std.algorithm: count;
	immutable stripped = s.strip;
	result &= stripped.count('<') == 1;
	result &= stripped.startsWith("<!-- sitegen ") && stripped.endsWith(" -->");
	return result;
}
