const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");

const client = new DynamoDBClient({});

const isApiGateway = (event) => !!event?.requestContext;

const response = (statusCode, body) => ({
  statusCode,
  headers: {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
  },
  body: JSON.stringify(body)
});

const replaceAll = (str, find, replace) => {
  return str.replace(new RegExp(find, "g"), replace);
};

exports.handler = async (event = {}) => {
  try {
    console.log("EVENT:", JSON.stringify(event, null, 2));

    const body = event?.body ? JSON.parse(event.body) : event;

    if (!body.title || !body.authorId || !body.length || !body.category) {
      const result = {
        message: "title, authorId, length and category are required"
      };

      return isApiGateway(event) ? response(400, result) : result;
    }

    const id = body.id || replaceAll(body.title, " ", "-").toLowerCase();

    const course = {
      id,
      title: body.title,
      watchHref: body.watchHref || `http://www.pluralsight.com/courses/${id}`,
      authorId: body.authorId,
      length: body.length,
      category: body.category
    };

    const tableName = process.env.COURSES_TABLE_NAME;

    if (!tableName) {
      const result = {
        message: "COURSES_TABLE_NAME environment variable is not set"
      };

      return isApiGateway(event) ? response(500, result) : result;
    }

    await client.send(new PutItemCommand({
      TableName: tableName,
      Item: {
        id: { S: course.id },
        title: { S: course.title },
        watchHref: { S: course.watchHref },
        authorId: { S: course.authorId },
        length: { S: course.length },
        category: { S: course.category }
      }
    }));

    return isApiGateway(event) ? response(200, course) : course;
  } catch (error) {
    console.error("SAVE COURSE ERROR:", error);

    const result = {
      message: error.message
    };

    return isApiGateway(event) ? response(500, result) : result;
  }
};
