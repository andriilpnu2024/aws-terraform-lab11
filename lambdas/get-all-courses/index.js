const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });

const isApiGateway = (event) => !!event?.requestContext;
const response = (statusCode, body) => ({ statusCode, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, body: JSON.stringify(body) });

exports.handler = async (event = {}) => {
  try {
    const data = await client.send(new ScanCommand({ TableName: process.env.COURSES_TABLE_NAME }));
    const courses = (data.Items || []).map((item) => ({
      id: item.id?.S,
      title: item.title?.S,
      watchHref: item.watchHref?.S,
      authorId: item.authorId?.S,
      length: item.length?.S,
      category: item.category?.S,
    }));

    return isApiGateway(event) ? response(200, courses) : courses;
  } catch (error) {
    console.error(error);
    return isApiGateway(event) ? response(500, { message: error.message }) : { message: error.message };
  }
};
