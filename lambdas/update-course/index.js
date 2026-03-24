const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });

const isApiGateway = (event) => !!event?.requestContext;
const response = (statusCode, body) => ({ statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) });

exports.handler = async (event = {}) => {
  try {
    const body = event?.body ? JSON.parse(event.body) : event;
    const id = event?.pathParameters?.id || body?.id;

    if (!id || !body.title || !body.authorId || !body.length || !body.category || !body.watchHref) {
      return isApiGateway(event) ? response(400, { message: 'id, title, authorId, length, category, watchHref are required' }) : { message: 'id, title, authorId, length, category, watchHref are required' };
    }

    const item = {
      id: { S: id },
      title: { S: body.title },
      watchHref: { S: body.watchHref },
      authorId: { S: body.authorId },
      length: { S: body.length },
      category: { S: body.category },
    };

    await client.send(new PutItemCommand({ TableName: process.env.COURSES_TABLE_NAME, Item: item }));

    const result = {
      id,
      title: body.title,
      watchHref: body.watchHref,
      authorId: body.authorId,
      length: body.length,
      category: body.category,
    };

    return isApiGateway(event) ? response(200, result) : result;
  } catch (error) {
    console.error(error);
    return isApiGateway(event) ? response(500, { message: error.message }) : { message: error.message };
  }
};
