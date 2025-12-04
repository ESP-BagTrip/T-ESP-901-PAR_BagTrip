import { DynamicStructuredTool } from '@langchain/core/tools';
import { z } from 'zod';
import { searchLocationsByKeyword } from '../../travel/travel.service';
import { Location } from '../../../integrations/amadeus/amadeus.types';

/**
 * Schema for the search locations tool parameters
 */
const searchLocationsSchema = z.object({
  subType: z.string().describe('Comma-separated list of location sub-types (e.g., "CITY,AIRPORT")'),
  keyword: z.string().describe('Search keyword for location name (e.g., "paris", "new york")'),
});

/**
 * Format a location to a concise Markdown string
 */
function formatLocation(location: Location): string {
  const parts: string[] = [];

  // Main identifier
  parts.push(`**${location.name}**`);
  if (location.detailedName && location.detailedName !== location.name) {
    parts.push(`(${location.detailedName})`);
  }

  // Type and code
  const typeInfo: string[] = [location.subType];
  if (location.iataCode) {
    typeInfo.push(`IATA: ${location.iataCode}`);
  }
  parts.push(`[${typeInfo.join(', ')}]`);

  // Location details
  const locationDetails: string[] = [];
  if (location.address.cityName) {
    locationDetails.push(location.address.cityName);
  }
  if (location.address.countryName) {
    locationDetails.push(location.address.countryName);
  }
  if (locationDetails.length > 0) {
    parts.push(`📍 ${locationDetails.join(', ')}`);
  }

  // ID for reference
  parts.push(`\`ID: ${location.id}\``);

  return parts.join(' ');
}

/**
 * Format search results to a clear and concise Markdown response
 */
function formatLocationSearchResult(result: { locations: Location[]; count: number }): string {
  if (result.count === 0) {
    return '## Résultats de recherche\n\nAucune localisation trouvée pour cette recherche.';
  }

  const lines: string[] = [];
  lines.push(`## Résultats de recherche (${result.count} résultat${result.count > 1 ? 's' : ''})`);
  lines.push('');

  result.locations.forEach((location, index) => {
    lines.push(`${index + 1}. ${formatLocation(location)}`);
  });

  return lines.join('\n');
}

/**
 * Tool for searching locations by keyword
 * Converts the travel service function into a LangChain tool
 */
export const searchLocationsByKeywordTool = new DynamicStructuredTool({
  name: 'search_locations_by_keyword',
  description:
    'Search for locations like cities or airports by keyword. Use this tool when the user asks about finding a location, city, airport, or place.',
  schema: searchLocationsSchema,
  func: async ({ subType, keyword }: { subType: string; keyword: string }) => {
    try {
      const result = await searchLocationsByKeyword({ subType, keyword });
      return formatLocationSearchResult(result);
    } catch (error: any) {
      return `## Erreur\n\nImpossible de rechercher les localisations: ${error.message || 'Erreur inconnue'}`;
    }
  },
});

/**
 * Get all travel-related tools
 * This function can be extended to include more tools in the future
 */
export function getTravelTools(): DynamicStructuredTool[] {
  return [searchLocationsByKeywordTool];
}
