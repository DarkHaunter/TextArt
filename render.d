import std.file;
import std.format;
import std.stdio;
import std.math;
import std.string;
import std.algorithm;
import std.range;

ubyte[128][128] fontBitmap;
int[256] fontWidth;
ubyte getFontPixel(ubyte c, int x, int y) { return x<8 ? fontBitmap[c/16*8+y][c%16*8+x] : 0; }

ubyte[] image, preview;
int w, h;
ubyte getPixel(int x, int y) { return x<w && y<h ? image[y*w+x] : 0; }
void putPixel(int x, int y, ubyte p) { if (x<w && y<h) preview[y*w+x] = p; }

int checkChar(ubyte c, int x, int y)
{
	int diff;
	foreach (cy; 0..8)
		foreach (cx; 0..fontWidth[c]+1)
			diff += abs(cast(int)getPixel(x+cx, y+cy) - cast(int)getFontPixel(c, cx, cy));
	return diff;
}

void drawChar(ubyte c, int x, int y)
{
	foreach (cy; 0..8)
		foreach (cx; 0..fontWidth[c]+1)
			putPixel(x+cx, y+cy, getFontPixel(c, cx, cy));
}

void main()
{
	(cast(ubyte[])fontBitmap)[] = cast(ubyte[])read("font.pbm")[15..$];
	
	foreach (c; 0..256)
	{
		int cx = c%16 * 8;
		int cy = c/16 * 8;
		int width;
		for (width=0; width<8; width++)
		{
			bool blank = true;
			foreach (y; 0..8)
				if (fontBitmap[cy+y][cx+width])
					{ blank = false; break; }
			if (blank)
				break;
		}
		fontWidth[c] = width;
	}

	assert(fontWidth['.'] == 1);
	fontWidth[32] = 3;

	string imageData = cast(string)read("image.pbm");
	string type; int maxLevel;
	formattedRead(imageData, "%s\n%d\n%d\n%d\n", &type, &w, &h, &maxLevel);
	assert(type == "P5");
	assert(maxLevel == 255);

	image = cast(ubyte[])imageData;
	preview.length = image.length;

	auto result = File("text.txt", "w");

	for (int y=0; y<h; y+=9)
	{
		struct Progress
		{
			int score = int.max;
			ubyte c;
		}
		auto progress = new Progress[w+9];
		progress[0].score = 0;

		foreach (x, p; progress[0..w]) if (p.score < int.max)
		{
			foreach (ubyte c; 32..127) if (c != '`' && (x>0 || c != ' '))
			{
				int x2 = x + fontWidth[c] + 1;
				int score2 = p.score + checkChar(c, x, y);
				if (progress[x2].score > score2)
					progress[x2].score = score2,
					progress[x2].c = c;
			}
		}

		uint minProgressScore(uint a, uint b) { return progress[a].score < progress[b].score ? a : b; }
		int x = reduce!minProgressScore(iota(w, progress.length));
		string s;
		while (x)
		{
			auto c = progress[x].c;
			s = cast(char)c ~ s;
			x -= fontWidth[c] + 1;
			drawChar(c, x, y);
		}

		result.writeln(s);
	}

	std.file.write("preview.pbm", cast(ubyte[])format("P5\n%d\n%d\n255\n", w, h) ~ preview);
}
