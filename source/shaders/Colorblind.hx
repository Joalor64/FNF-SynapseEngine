package shaders;

import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

class Colorblind
{
	public static var filters:Array<BitmapFilter> = [];
	public static var matrices:Map<String, Array<Float>> = [
		"Deuteranopia" => [
			 0.43, 0.72, -0.15, 0, 0,
			 0.34, 0.57,  0.09, 0, 0,
			-0.02, 0.03,  1.00, 0, 0,
			    0,    0,     0, 1, 0
		],
		"Deuteranomaly" => [
			  0.8,   0.2,     0, 0, 0,
			0.258, 0.742,     0, 0, 0,
			    0, 0.142, 0.858, 0, 0,
			    0,     0,     0, 1, 0
		],
		"Protanopia" => [
			0.20,  0.99, -0.19, 0, 0,
			0.16,  0.79,  0.04, 0, 0,
			0.01, -0.01,  1.00, 0, 0,
			   0,     0,     0, 1, 0
		],
		"Protanomaly" => [
			0.817, 0.183,     0, 0, 0,
			0.333, 0.667,     0, 0, 0,
			    0, 0.125, 0.875, 0, 0,
			    0,     0,     0, 1, 0
		],
		"Tritanopia" => [
			0.97, 0.11, -0.08, 0, 0,
			0.02, 0.82,  0.16, 0, 0,
			0.06, 0.88,  0.18, 0, 0,
			   0,    0,     0, 1, 0
		],
		"Tritanomaly" => [
			0.967, 0.033,     0, 0, 0,
			    0, 0.733, 0.267, 0, 0,
			    0, 0.183, 0.817, 0, 0,
			    0,     0,     0, 1, 0
		],
		"Achromatopsia" => [
			0.299, 0.587, 0.114, 0, 0,
			0.299, 0.587, 0.114, 0, 0,
			0.299, 0.587, 0.114, 0, 0,
			    0,     0,     0, 1, 0
		],
		"Achromatomaly" => [
			0.618, 0.320, 0.062, 0, 0,
			0.163, 0.775, 0.062, 0, 0,
			0.163, 0.320, 0.516, 0, 0,
			    0,     0,     0, 1, 0
		]
	];

	public function new()
	{
		if (filters.length > 0)
			FlxG.game.setFilters(filters);
	}

	public static function updateFilter()
	{
		filters = [];

		if (!ClientPrefs.data.shaders)
		{
			FlxG.game.setFilters(filters);
			return;
		}

		var name = ClientPrefs.data.colorBlindFilter;
		var matrix = matrices.get(name);

		if (matrix != null)
		{
			filters.push(new ColorMatrixFilter(matrix));
		}

		FlxG.game.setFilters(filters);
	}

	public static function getFilterNames():Array<String>
	{
		return [
			"None",
			"Protanopia",
			"Protanomaly",
			"Deuteranopia",
			"Deuteranomaly",
			"Tritanopia",
			"Tritanomaly",
			"Achromatopsia",
			"Achromatomaly"
		];
	}
}
