const { DynamoDBClient, DeleteItemCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });

const isApiGateway = (event) => !!event?.requestContext;
const response = (statusCode, body) => ({ statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) });

exports.handler = async (event = {}) => {
  try {
    const id = event?.pathParameters?.id || event?.id;

    if (!id) {
      return isApiGateway(event) ? response(400, { message: 'id is required' }) : { message: 'id is required' };
    }

    await client.send(new DeleteItemCommand({
      TableName: process.env.COURSES_TABLE_NAME,
      Key: { id: { S: id } },
    }));

    const result = { message: 'Course deleted', id };
    return isApiGateway(event) ? response(200, result) : result;
  } catch (error) {
    console.error(error);
    return isApiGateway(event) ? response(500, { message: error.message }) : { message: error.message };
  }
};
