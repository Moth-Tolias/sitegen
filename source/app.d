///
import sitegen.directives;
import std.datetime: DateTime;

void main(string[] args) //@safe
{
	immutable options = handleOptions(args);
	compileSite(options);
}

void compileSite(in Options options) //@safe
{
	immutable path = options.inputPath;
	import std.file: dirEntries, SpanMode;
	foreach(entry; dirEntries(path, "*.html", SpanMode.breadth))
	{
		compilePage(entry, options);
	}
}

void compilePage(in string path, in Options options)
in
{
	import std.file: exists, isDir;
	assert(path.exists && !(path.isDir));
}
do
{
	immutable inputPath = options.inputPath;
	immutable outputPath = getOutputPath(path, options.outputPath);

	import std.file: mkdirRecurse;
	import std.path: dirName;
	mkdirRecurse(dirName(outputPath));

	import std.stdio: File;
	auto compiledPage = File(outputPath, "w");
	compiledPage.writeln(executeCallDirective(path, inputPath, 0));
	compiledPage.close;
}

string parseAndExecute(in string s, in string inputPath, in int indentation = 0)
{
	immutable parsed = parse(s);
	final switch(parsed.d) with (Directive)
	{
		case Include: return executeIncludeDirective(parsed.s, inputPath, indentation);
		case Call: return executeCallDirective(parsed.s, inputPath, indentation);
		case Echo: return "echo:" ~ parsed.s;
		case Time: return getCurrentTime.toISOExtString();
		case None: return s;
	}
}

int getIndentationLevel(in string line) pure @safe
{
	import std.string: lastIndexOf;
	return cast(int)lastIndexOf(line, "\t") + 1;
}

string getOutputPath(in string inputPath, in string outputPath) @safe
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
	return buildNormalizedPath(getcwd(), outputPath, filename);
}

string executeIncludeDirective(in string includes, in string inputPath, in int indentation)
{
	string result;
	import std.path: buildNormalizedPath;
	import std.string: split;
	foreach(s; includes.split)
	{
		result ~= include(buildNormalizedPath(inputPath, s), indentation);
	}
	return result;
}

string executeCallDirective(in string args, in string inputPath, in int indentation)
{
	import std.path: buildNormalizedPath;
	import std.string: split;
	immutable path = buildNormalizedPath(inputPath, args.split[0]);

	string result;

	import std.stdio: File;
	auto source = File(path, "r");
	foreach(line; source.byLineCopy)
	{
		if(line.isDirective) //todo: does this really need to be special cased?
		{
			result ~= parseAndExecute(line, inputPath, getIndentationLevel(line));
			result ~= '\n';
			continue;
		}

		string toParse;
		bool checking;

		foreach(c; line)
		{
			if(c == '<')
			{
				checking = true;
			}

			if(checking)
			{
				toParse ~= c;

				if(c == '>')
				{
					if(toParse.isDirective)
					{
						result ~= parseAndExecute(toParse, inputPath);
					}
					else
					{
						result ~= toParse;
					}

					checking = false;
					toParse = "";
				}
			}
			else
			{
				result ~= c;
			}
		}

		result ~= '\n';
	}

	return result;
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

Options handleOptions(in string[] args) @safe
{
	Options result;
	import std.path: buildNormalizedPath;
	import std.file: getcwd;
	result.inputPath = buildNormalizedPath(getcwd(), "site");
	result.outputPath = buildNormalizedPath(getcwd(), "out");
	return result;
}

struct Options
{
	string inputPath;
	string outputPath;
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
