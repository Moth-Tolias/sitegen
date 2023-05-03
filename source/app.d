///
import std.stdio;
import std.file;
import std.path;

void main(string[] args) //@safe
{
	immutable options = handleOptions(args);
	compileSite(options.inputPath);
}

void compileSite(in string path) //@safe
{
	foreach(entry; dirEntries(path, "*.html", SpanMode.breadth))
	{
		compilePage(entry, path);
	}
}

void compilePage(in string path, string inputPath)
in(path.exists && !(path.isDir))
{
	immutable outputPath = getOutputPath(path);
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
	return buildNormalizedPath(inputPath, s[2]);
}

string include(string path, int indentation)
{
	string result;
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
	result.inputPath = buildNormalizedPath(getcwd(), "site");
	return result;
}

struct Options
{
	string inputPath;
	string outputPath;
}
