import swaggerJsdoc from 'swagger-jsdoc';
import { env } from './env';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Gospalaga API',
      version: '1.0.0',
      description: 'API documentation for Gospalaga travel services',
      contact: {
        name: 'API Support',
      },
    },
    servers: [
      {
        url: `http://localhost:${env.PORT}`,
        description: 'Development server',
      },
      {
        url: 'https://api.gospalaga.com',
        description: 'Production server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT token authentication. Format: Bearer <token>',
        },
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            message: {
              type: 'string',
              description: 'Error message',
            },
            statusCode: {
              type: 'number',
              description: 'HTTP status code',
            },
          },
        },
        Location: {
          type: 'object',
          properties: {
            type: {
              type: 'string',
              description: 'Location type',
            },
            subType: {
              type: 'string',
              description: 'Location sub-type (CITY, AIRPORT, etc.)',
            },
            name: {
              type: 'string',
              description: 'Location name',
            },
            detailedName: {
              type: 'string',
              description: 'Detailed location name',
            },
            id: {
              type: 'string',
              description: 'Location ID',
            },
            iataCode: {
              type: 'string',
              description: 'IATA code if applicable',
            },
            geoCode: {
              type: 'object',
              properties: {
                latitude: {
                  type: 'number',
                },
                longitude: {
                  type: 'number',
                },
              },
            },
            address: {
              type: 'object',
              properties: {
                cityName: {
                  type: 'string',
                },
                cityCode: {
                  type: 'string',
                },
                countryName: {
                  type: 'string',
                },
                countryCode: {
                  type: 'string',
                },
                regionCode: {
                  type: 'string',
                },
              },
            },
            timeZoneOffset: {
              type: 'string',
              description: 'Time zone offset',
            },
          },
        },
        LocationSearchResult: {
          type: 'object',
          properties: {
            locations: {
              type: 'array',
              items: {
                $ref: '#/components/schemas/Location',
              },
            },
            count: {
              type: 'number',
              description: 'Number of locations found',
            },
          },
        },
      },
    },
  },
  apis: ['./src/**/*.ts'], // Chemin vers les fichiers contenant les annotations Swagger
};

export const swaggerSpec = swaggerJsdoc(options);
