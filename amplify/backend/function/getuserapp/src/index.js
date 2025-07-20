// index.js
import {
    CognitoIdentityProviderClient,
    ListUsersCommand,
    ListUsersInGroupCommand,
} from "@aws-sdk/client-cognito-identity-provider";

const cognito = new CognitoIdentityProviderClient({});

const USER_POOL_ID = process.env.USER_POOL_ID;

export const handler = async (event) => {
  const groupName = event.groupName || null;

  try {
    let users = [];
    let nextToken = undefined;

    if (groupName) {
      // Listar usuarios en un grupo
      do {
        const command = new ListUsersInGroupCommand({
          UserPoolId: USER_POOL_ID,
          GroupName: groupName,
          Limit: 60,
          NextToken: nextToken,
        });

        const response = await cognito.send(command);
        users.push(...response.Users);
        nextToken = response.NextToken;
      } while (nextToken);
    } else {
      // Listar todos los usuarios
      do {
        const command = new ListUsersCommand({
          UserPoolId: USER_POOL_ID,
          Limit: 60,
          PaginationToken: nextToken,
        });

        const response = await cognito.send(command);
        users.push(...response.Users);
        nextToken = response.PaginationToken;
      } while (nextToken);
    }

    const formattedUsers = users.map((user) => ({
      username: user.Username,
      enabled: user.Enabled,
      status: user.UserStatus,
      createdAt: user.UserCreateDate,
      email: user.Attributes?.find((a) => a.Name === "email")?.Value,
      negocioId: user.Attributes?.find((a) => a.Name === "custom:negocio_id")?.Value,
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({ users: formattedUsers }),
    };
  } catch (err) {
    console.error("Error listing users:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message }),
    };
  }
};
