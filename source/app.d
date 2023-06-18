///

import std.datetime: DateTime;

void main(string[] args) //@safe
{
	immutable options = handleOptions(args);
	compileSite(options.inputPath);
}

void compileSite(in string path) //@safe
{
	import std.file: dirEntries, SpanMode;
	foreach(entry; dirEntries(path, "*.html", SpanMode.breadth))
	{
		compilePage(entry, path);
	}
}

DateTime getCurrentTime() @safe
{
	import std.datetime: Clock;
	return cast(DateTime) Clock.currTime();
}

string timeToString(in DateTime dateTime) pure @safe
{
	import std.string;
	immutable raw =	dateTime.toISOExtString();
	immutable formatted = raw.replace("T", " ");
	return "<time datetime=\"" ~ raw ~ "\">" ~ formatted ~ "</time>";
}

void compilePage(in string path, string inputPath)
in
{
	import std.file: exists, isDir;
	assert(path.exists && !(path.isDir));
}
do
{
	immutable outputPath = getOutputPath(path);

	import std.file: mkdirRecurse;
	import std.path: dirName;
	import std.stdio: File;
	mkdirRecurse(dirName(outputPath));
	auto compiledPage = File(outputPath, "w");

	auto source = File(path, "r");
	foreach(line; source.byLineCopy)
	{
		if(line.isIncludeDirective)
		{
			immutable indentation = getIndentationLevel(line);
			immutable fname = parseIncludeDirective(line, inputPath);
			compiledPage.writeln(include(fname, indentation));
		}
		else
		{
			compiledPage.writeln(line);
		}
	}

	compiledPage.close;
}

int getIndentationLevel(in string line) pure @safe
{
	import std.string: lastIndexOf;
	return cast(int)lastIndexOf(line, "\t") + 1;
}

enum Directive
{
	None, //normal text
	Include,
	BuiltIn,
	Function
}

Directive LineToDirective(in string line)
{
	if(line.isIncludeDirective)
	{
		return Directive.Include;
	}
	else if(line.isBuiltInDirective)
	{
		return Directive.BuiltIn;
	}
	else if(line.isBuiltInDirective)
	{
		return Directive.Function;
	}

	return Directive.None;
}

string getOutputPath(in string inputPath) @safe
out(r)
{
	import std.path: isValidPath;
	assert(isValidPath(r));
}
do
{
	import std.file: getcwd;
	import std.path: relativePath, buildNormalizedPath;
	auto filename = relativePath(inputPath, getcwd());
	return buildNormalizedPath(getcwd(), "out", filename);
}

string parseIncludeDirective(in string line, in string inputPath) pure @safe
{
	import std.array: split;
	auto s = split(line);

	import std.path: buildNormalizedPath;
	return buildNormalizedPath(inputPath, s[2]);
}

string include(string path, int indentation)
{
	string result;
	import std.stdio: File;
	auto f = File(path, "r");
	foreach(line; f.byLine)
	{
		if (line != "")
		{
			foreach(_; 0 .. indentation)
			{
				result ~= "\t";
			}
		}

		if(!f.eof)
		{
			result ~= line ~ "\n";
		}
	}

	return result[0 .. $-1];
}

bool isIncludeDirective(in string line)
{
	import std.string;
	immutable stripped = line.strip;
	return stripped.startsWith("<!-- include ") && stripped.endsWith(" -->");
}

Options handleOptions(in string[] args) @safe
{
	Options result;
	import std.path: buildNormalizedPath;
	import std.file: getcwd;
	result.inputPath = buildNormalizedPath(getcwd(), "site");
	return result;
}

struct Options
{
	string inputPath;
	string outputPath;
}
