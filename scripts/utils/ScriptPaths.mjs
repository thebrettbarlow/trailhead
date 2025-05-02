import path from 'path';
import { SfProject } from '@salesforce/core';

export class ScriptPaths {
  static _scriptsDir;

  static async scriptsDir() {
    if (!this._scriptsDir) {
      const project = await SfProject.resolve();
      this._scriptsDir = path.join(project.getPath(), 'scripts');
    }

    return this._scriptsDir;
  }

  static async updateManifest() {
    return path.join(await this.scriptsDir(), 'update-manifest.sh');
  }

  static async listApexTests() {
    return path.join(await this.scriptsDir(), 'list-apex-tests.mjs');
  }

  static async apexTestOperator() {
    return path.join(await this.scriptsDir(), 'apex-test-operator.sh');
  }
}
