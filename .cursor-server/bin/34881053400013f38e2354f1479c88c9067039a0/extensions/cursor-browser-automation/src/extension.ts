import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { MCPServer } from './mcpServer.js';

let mcpServer: MCPServer | undefined;

export function activate(context: vscode.ExtensionContext) {
	console.log('Cursor Browser Automation extension activated');

	// Register command to start MCP server
	context.subscriptions.push(
		vscode.commands.registerCommand('cursor.browserAutomation.start', async (preferredPort?: number, reuseExisting = true) => {
			try {
				if (!mcpServer) {
					mcpServer = new MCPServer(vscode.commands);
					const { port, reused } = await mcpServer.start(preferredPort, reuseExisting);

					return { success: true, mcpPort: port, running: true, reused };
				}
				return {
					success: true,
					mcpPort: mcpServer.getPort(),
					running: true,
					reused: false
				};
			} catch (error) {
				vscode.window.showErrorMessage(`Failed to start MCP server: ${error}`);
				return { success: false, error: String(error), running: false };
			}
		})
	);

	// Register command to stop MCP server
	context.subscriptions.push(
		vscode.commands.registerCommand('cursor.browserAutomation.stop', () => {
			if (mcpServer) {
				mcpServer.stop();
				mcpServer = undefined;

				return { success: true, running: false };
			}
			return { success: true, running: false };
		})
	);

	// Register command to get MCP server status
	context.subscriptions.push(
		vscode.commands.registerCommand('cursor.browserAutomation.getStatus', () => {
			const status = {
				running: !!mcpServer,
				mcpPort: mcpServer?.getPort()
			};
			return status;
		})
	);

}

export function deactivate() {
	mcpServer?.stop();
}