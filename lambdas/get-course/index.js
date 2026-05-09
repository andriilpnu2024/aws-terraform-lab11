const { DynamoDBClient, GetItemCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });

const isApiGateway = (event) => !!event?.requestContext;
const response = (statusCode, body) => ({ statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) });

exports.handler = async (event = {}) => {
  try {
    const id = event?.pathParameters?.id || event?.id;

    if (!id) {
      return isApiGateway(event) ? response(400, { message: 'id is required' }) : { message: 'id is required' };
    }

    const data = await client.send(new GetItemCommand({
      TableName: process.env.COURSES_TABLE_NAME,
      Key: { id: { S: id } },
    }));

    if (!data.Item) {
      return isApiGateway(event) ? response(404, { message: 'Course not found' }) : { message: 'Course not found' };
    }

    const course = {
      id: data.Item.id?.S,
      title: data.Item.title?.S,
      watchHref: data.Item.watchHref?.S,
      authorId: data.Item.authorId?.S,
      length: data.Item.length?.S,
      category: data.Item.category?.S,
    };

    return isApiGateway(event) ? response(200, course) : course;
  } catch (error) {
    console.error(error);
    return isApiGateway(event) ? response(500, { message: error.message }) : { message: error.message };
  }
};
