# epansa_app

Your personal AI-powered mobile assistant.

## Getting Started

The 'epansa_app' is a Flutter application that implements an AI-powered agent capable of interacting with various tools and apps inside a mobile device, acting as a personal assistant. 

## Features

- The actual agent is hosted on a server and can be accessed via API.
- The app provides a user interface for interacting with the agent.
- The agent can use tools such as web search, calendar management, and note-taking apps integrated with the google ecosystem.
- The remote agent can also send some commands to the app to perform actions on the device, to perform tasks that require local access like sending SMS, making phone calls, accessing local files and wake up alarms.
- It requires the user to authenticate with Google to access the necessary services, sending an OAuth token to the remote agent.
- The app is designed to be easily extendable, allowing for the addition of new tools and functionalities.
- The app can sync the phone informations that aren't integrated with the google ecosystem (contacts, tasks, notes, alarms) with the remote agent to provide a more personalized experience, the remote agent will index this data to be able to answer questions and perform tasks based on the user's data. This process can be done synchronously with a sync button or asynchronously in the background.
- The app also includes a chat interface for direct communication with the agent, allowing users to ask questions and receive responses in real-time. It supports both text and voice input, as well as displaying images and other media in the chat.
- It should implement also a user confirmation component to confirm actions that can have significant consequences, such as sending messages or making phone calls.