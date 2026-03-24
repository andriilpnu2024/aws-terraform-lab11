const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });

const isApiGateway = (event) => !!event?.requestContext;
const response = (statusCode, body) => ({ statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) });
const slugify = (value) => value.toLowerCase().trim().replace(/\s+/g, '-');

exports.handler = async (event = {}) => {
  try {
    const payload = event?.body ? JSON.parse(event.body) : event;
    const id = slugify(payload.title || '');

    if (!payload.title || !payload.authorId || !payload.length || !payload.category) {
      return isApiGateway(event) ? response(400, { message: 'title, authorId, length, category are required' }) : { message: 'title, authorId, length, category are required' };
    }

    const item = {
      id: { S: id },
      title: { S: payload.title },
      watchHref: { S: `http://www.pluralsight.com/courses/${id}` },
      authorId: { S: payload.authorId },
      length: { S: payload.length },
      category: { S: payload.category },
    };

    await client.send(new PutItemCommand({ TableName: process.env.COURSES_TABLE_NAME, Item: item }));

    const result = {
      id,
      title: payload.title,
      watchHref: `http://www.pluralsight.com/courses/${id}`,
      authorId: payload.authorId,
      length: payload.length,
      category: payload.category,
    };

    return isApiGateway(event) ? response(200, result) : result;
  } catch (error) {
    console.error(error);
    return isApiGateway(event) ? response(500, { message: error.message }) : { message: error.message };
  }
};
