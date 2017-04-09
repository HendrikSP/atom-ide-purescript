module IdePurescript.Atom.Config (config, getSrcGlob, getFastRebuild) where

import Prelude
import Node.Process as P
import Atom.Atom (getAtom)
import Atom.Config (CONFIG, getConfig)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Except (runExcept)
import Data.Array (mapMaybe)
import Data.Bifunctor (rmap)
import Data.Either (either)
import Data.Foreign (readString, readArray, readBoolean, Foreign, toForeign)
import Data.Maybe (Maybe(..))
import Node.Platform (Platform(Win32))

defaultSrcGlob :: Array String
defaultSrcGlob = ["src/**/*.purs", "bower_components/**/*.purs"]

getSrcGlob :: forall eff. Eff (config :: CONFIG | eff) (Array String)
getSrcGlob = do
  atom <- getAtom
  srcGlob <- liftEff $ runExcept <$> readArray <$> getConfig atom.config "ide-purescript.pscSourceGlob"
  let srcGlob' = rmap (mapMaybe $ (either (const Nothing) Just) <<< runExcept <<< readString) $ srcGlob
  pure $ either (const defaultSrcGlob) id $ srcGlob'

getFastRebuild :: forall eff. Eff (config :: CONFIG | eff) Boolean
getFastRebuild = do
  atom <- getAtom
  fastRebuild <- readBoolean <$> getConfig atom.config "ide-purescript.fastRebuild"
  pure $ either (const true) id $ runExcept fastRebuild

pulpCmd :: String
pulpCmd = if P.platform == Win32 then "pulp.cmd" else "pulp"

config :: Foreign
config = toForeign
  { pscSourceGlob:
    { title: "PureScript source glob"
    , description: "Source glob to use to find .purs source files. Currently used for psc-ide-server to power goto-definition. (Requires restart/server restart command)"
    , type: "array"
    , default: defaultSrcGlob
    , items:
      { type: "string"
      }
    }
  , pscIdeServerExe:
    { title: "psc-ide-server executable location"
    , description: "The location of the `psc-ide-server` executable. Note this is *not* `psc-ide-client`. May be on the PATH. (Requires restart/server restart command)"
    , type: "string"
    , default: "psc-ide-server"
    }
  , pursExe:
    { title: "purs location"
    , description: "The location of the combined `purs` executable. May be on the PATH. (Requires restart/server restart command)"
    , type: "string"
    , default: "purs"
    }
  , useCombinedExe:
    { title: "Use combined executable"
    , description: "Whether to use the new combined purs executable. This will default to true in the future then go away."
    , type: "boolean"
    , default: false
    }
  , addNpmPath:
    { title: "Use npm bin directory"
    , description: "Whether to add the local npm bin directory to the PATH (e.g. to use locally installed purs/psc-ide-server if available). (Requires restart/server restart command)"
    , type: "boolean"
    , default: false
    }
  , buildCommand:
    { title: "Build command"
    , description: "Command line to build the project. "
        <> "Could be pulp (default), psc or a gulpfile, so long as it passes through errors from psc. "
        <> "Should output json errors (`--json-errors` flag). "
        <> "This is not interpreted via a shell, arguments can be specified but don't use shell features or a command with spaces in its path."
        <> "See [examples on the README](https://github.com/nwolverson/atom-ide-purescript/#build-configuration-hints)"
    , type: "string"
    , default: pulpCmd <> " build -- --json-errors"
    }
  , buildOnSave:
    { title: "Build on save"
    , description: "Build automatically on save. Enables in-line and collected errors. Otherwise a build command is available to be invoked manually."
    , type: "boolean"
    , default: true
    }
  , fastRebuild:
    { title: "Use fast rebuild"
    , description: "Use psc-ide-server rebuild function to build the current file only on save"
    , type: "boolean"
    , default: true
    }
  , censorWarnings:
    { title: "Censor warnings"
    , description: "The warning codes to censor, both for fast rebuild and a full build. Unrelated to any psa setup. e.g.: ShadowedName,MissingTypeDeclaration"
    , type: "array"
    , default: []
    , items:
      { type: "string"
      }
    }
  , psciCommand:
    { title: "psci command (eg 'psci' or 'pulp psci' or full path)"
    , description: "Command line to use to launch PSCI for the repl buffer. "
        <> "This is not interpreted via a shell, arguments can be specified but don't use shell features or a command with spaces in its path."
    , type: "string"
    , default: pulpCmd <> " psci"
    }
  , autocomplete:
    { type: "object"
    , properties:
      { addImport:
        { title: "Add import on autocomplete"
        , description: "Whether to automatically add imported identifiers when accepting autocomplete result."
        , type: "boolean"
        , default: true
        }
      , allModules:
        { title: "Suggest from all modules"
        , description: "Whether to always autocomplete from all built modules, or just those imported in the file. Suggestions from all modules always available by explicitly triggering autocomplete."
        , type: "boolean"
        , default: true
        }
      , excludeLowerPriority:
        { title: "Exclude other lower-priority providers"
        , description: "Whether to set the excludeLowerPriority flag for autocomplete+: disable this to see plain-text suggestions from context, for example. (Requires restart)"
        , type: "boolean"
        , default: true
        }
      }
    }
  }
