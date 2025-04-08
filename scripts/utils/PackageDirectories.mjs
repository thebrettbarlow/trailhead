import path from 'path';
import { SfProject } from '@salesforce/core';
import { glob } from 'glob';

export class PackageDirectories {
  static async listPackageXmls() {
    const project = await SfProject.resolve();

    const packageDirs = await glob(`${project.getPath()}/**/package.xml`, {
      ignore: ['**/node_modules/**']
    });

    if (packageDirs.length === 0) {
      throw new Error('No package.xml files found in the project.');
    }

    return packageDirs.map((file) =>
      path.dirname(file).replace(`${project.getPath()}/`, '')
    );
  }
}
