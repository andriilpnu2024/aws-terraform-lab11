const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });

const isApiGateway = (event) => !!event?.requestContext;
const response = (statusCode, body) => ({ statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) });

exports.handler = async (event = {}) => {
  try {
    const data = await client.send(new ScanCommand({ TableName: process.env.AUTHORS_TABLE_NAME }));
    const authors = (data.Items || []).map((item) => ({
      id: item.id?.S,
      firstName: item.firstName?.S,
      lastName: item.lastName?.S,
    }));

    return isApiGateway(event) ? response(200, authors) : authors;
  } catch (error) {
    console.error(error);
    return isApiGateway(event) ? response(500, { message: error.message }) : { message: error.message };
  }
};
