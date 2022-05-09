import glob from 'fast-glob';
import findUp from 'find-up';
import fs from 'fs-extra';
import path from 'path';

import { registerGlobMock, registerRequireMock } from '../../__tests__/mockHelpers';
import type { findModulesAsync as findModulesAsyncType } from '../findModules';

const expoRoot = path.join(__dirname, '..', '..', '..', '..', '..');

jest.mock('fast-glob');
jest.mock('find-up');
jest.mock('fs-extra');

// mock findUp.sync to fix `mergeLinkingOptions` package.json resolution when requiring `findModules`.
(findUp.sync as jest.MockedFunction<any>).mockReturnValueOnce(path.join(expoRoot, 'package.json'));
const mockProjectPackageJsonPath = jest.fn();
jest.mock('../mergeLinkingOptions', () => {
  const actualModule = jest.requireActual('../mergeLinkingOptions');
  return {
    ...actualModule,
    get projectPackageJsonPath() {
      return mockProjectPackageJsonPath();
    },
  };
});

const {
  findModulesAsync,
}: { findModulesAsync: typeof findModulesAsyncType } = require('../findModules');

describe(findModulesAsync, () => {
  beforeEach(() => {
    (fs.realpath as jest.MockedFunction<any>).mockImplementation((path) => Promise.resolve(path));
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  function addMockedModule(name: string, options?: { pkgDir?: string; pkgVersion?: string }) {
    const pkgDir = options?.pkgDir ?? path.join(expoRoot, 'node_modules', name);

    // mock require() call to module's package.json
    registerRequireMock(path.join(pkgDir, 'package.json'), {
      name,
      version: options?.pkgVersion ?? '0.0.1',
    });

    // mock require() call to module's expo-module.config.json
    registerRequireMock(path.join(pkgDir, 'expo-module.config.json'), {
      platforms: ['ios'],
    });
  }

  it('should link top level package', async () => {
    const searchPath = path.join(expoRoot, 'node_modules');
    addMockedModule('react-native-third-party');

    registerGlobMock(glob, ['react-native-third-party/expo-module.config.json'], searchPath);

    const result = await findModulesAsync({
      searchPaths: [searchPath],
      platform: 'ios',
    });
    expect(result['react-native-third-party']).not.toBeUndefined();
  });

  it('should link scoped level package', async () => {
    const searchPath = path.join(expoRoot, 'node_modules');
    const mockedModules = ['react-native-third-party', '@expo/expo-test'];
    for (const mockedModule of mockedModules) {
      addMockedModule(mockedModule);
    }

    registerGlobMock(
      glob,
      mockedModules.map((module) => `${module}/expo-module.config.json`),
      searchPath
    );

    const result = await findModulesAsync({
      searchPaths: [searchPath],
      platform: 'ios',
    });
    expect(Object.keys(result).length).toBe(2);
  });

  it('should link hoisted package in workspace', async () => {
    const appPackageJsonPath = path.join(expoRoot, 'packages', 'app', 'package.json');
    const appNodeModules = path.join(expoRoot, 'packages', 'app', 'node_modules');

    // mock app project package.json
    mockProjectPackageJsonPath.mockReturnValue(appPackageJsonPath);
    registerRequireMock(appPackageJsonPath, {
      name: 'app',
      version: '0.0.1',
      dependencies: {
        pkg: '*',
      },
    });

    // add mocked pkg
    const workspaceNodeModules = path.join(expoRoot, 'node_modules');
    const searchPaths = [appNodeModules, workspaceNodeModules];
    addMockedModule('pkg', { pkgDir: path.join(workspaceNodeModules, 'pkg') });
    registerGlobMock(glob, ['pkg/expo-module.config.json'], workspaceNodeModules);

    const result = await findModulesAsync({
      searchPaths,
      platform: 'ios',
    });

    expect(result['pkg']).not.toBeUndefined();
  });

  it('should link non-hoisted package from app project dependencies', async () => {
    const appPackageJsonPath = path.join(expoRoot, 'packages', 'app', 'package.json');
    const appNodeModules = path.join(expoRoot, 'packages', 'app', 'node_modules');

    // mock app project package.json
    mockProjectPackageJsonPath.mockReturnValue(appPackageJsonPath);
    registerRequireMock(appPackageJsonPath, {
      name: 'app',
      version: '0.0.1',
      dependencies: {
        pkg: '~1.0.0',
      },
    });

    // add mocked pkgs
    const workspaceNodeModules = path.join(expoRoot, 'node_modules');
    const searchPaths = [appNodeModules, workspaceNodeModules];
    addMockedModule('pkg', { pkgDir: path.join(workspaceNodeModules, 'pkg'), pkgVersion: '0.0.0' });
    addMockedModule('pkg', { pkgDir: path.join(appNodeModules, 'pkg'), pkgVersion: '1.0.0' });
    registerGlobMock(glob, ['pkg/expo-module.config.json'], workspaceNodeModules);
    registerGlobMock(glob, ['pkg/expo-module.config.json'], appNodeModules);

    const result = await findModulesAsync({
      searchPaths,
      platform: 'ios',
    });

    expect(result['pkg']).not.toBeUndefined();
    expect(result['pkg'].version).toEqual('1.0.0');
  });
});
